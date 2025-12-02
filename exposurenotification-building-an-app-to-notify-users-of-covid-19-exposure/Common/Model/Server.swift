/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class representing a local server that vends exposure data.
*/

import Foundation
import ExposureNotification
import CommonCrypto

struct CodableDiagnosisKey: Codable, Equatable {
    let keyData: Data
    let rollingPeriod: ENIntervalNumber
    let rollingStartNumber: ENIntervalNumber
    let transmissionRiskLevel: ENRiskLevel
}

struct CodableExposureConfiguration: Codable {
    // API V2 Keys
    let immediateDurationWeight: Double
    let nearDurationWeight: Double
    let mediumDurationWeight: Double
    let otherDurationWeight: Double
    let infectiousnessForDaysSinceOnsetOfSymptoms: [String: Int]
    let infectiousnessStandardWeight: Double
    let infectiousnessHighWeight: Double
    let reportTypeConfirmedTestWeight: Double
    let reportTypeConfirmedClinicalDiagnosisWeight: Double
    let reportTypeSelfReportedWeight: Double
    let reportTypeRecursiveWeight: Double
    let reportTypeNoneMap: Int
    // API V1 Keys
    let minimumRiskScore: ENRiskScore
    let attenuationDurationThresholds: [Int]
    let attenuationLevelValues: [ENRiskLevelValue]
    let daysSinceLastExposureLevelValues: [ENRiskLevelValue]
    let durationLevelValues: [ENRiskLevelValue]
    let transmissionRiskLevelValues: [ENRiskLevelValue]
}

// Replace this class with your own class that communicates with your server.
class Server {
    
    static let shared = Server()
    
    // For testing purposes, this object stores all of the TEKs it receives locally on device
    // In a real implementation, these would be stored on a remote server
    @Persisted(userDefaultsKey: "diagnosisKeys", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: [])
    var diagnosisKeys: [CodableDiagnosisKey]
    func postDiagnosisKeys(_ diagnosisKeys: [ENTemporaryExposureKey], completion: (Error?) -> Void) {
        
        // Convert keys to something that can be encoded to JSON and upload them.
        let codableDiagnosisKeys = diagnosisKeys.compactMap { diagnosisKey -> CodableDiagnosisKey? in
            return CodableDiagnosisKey(keyData: diagnosisKey.keyData,
                                       rollingPeriod: diagnosisKey.rollingPeriod,
                                       rollingStartNumber: diagnosisKey.rollingStartNumber,
                                       transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
        }
        
        // In a real implementation, these keys would be uploaded with URLSession instead of being saved here.
        // Your server needs to handle de-duplicating keys.
        for codableDiagnosisKey in codableDiagnosisKeys where !self.diagnosisKeys.contains(codableDiagnosisKey) {
            self.diagnosisKeys.append(codableDiagnosisKey)
        }
        completion(nil)
    }
    func getDiagnosisKeyFileURLs(startingAt index: Int, completion: (Result<[URL], Error>) -> Void) {
        
        // In a real implementation, these URLs would be retrieved from a server with URLSession
        // This sample only returns one placeholder URL, because the diagnosis key file is generated in each call to downloadDiagnosisKeyFile
        let remoteURLs = [URL(string: "/url/to/export\(index)")!]
        
        completion(.success(Array(remoteURLs[min(index, remoteURLs.count)...])))
    }
    
    // In a real implementation, this would be kept secret on your server
    // This is a sample private key - you will need to generate your own public-private key pair and share the public key with Apple
    // NOTE: The backslash on the end of the first line is not part of the key
    static let privateKeyECData = Data(base64Encoded: """
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgKJNe9P8hzcbVkoOYM4hJFkLERNKvtC8B40Y/BNpfxMeh\
    RANCAASfuKEs4Z9gHY23AtuMv1PvDcp4Uiz6lTbA/p77if0yO2nXBL7th8TUbdHOsUridfBZ09JqNQYKtaU9BalkyodM
    """)!
    
    // The URL passed to the completion is the local URL of the downloaded diagnosis key file
    func downloadDiagnosisKeyFile(at remoteURL: URL, completion: (Result<[URL], Error>) -> Void) {
        do {
            let attributes = [
                kSecAttrKeyType: kSecAttrKeyTypeEC,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                kSecAttrKeySizeInBits: 256
            ] as CFDictionary
            
            var cfError: Unmanaged<CFError>? = nil
            
            let privateKeyData = Server.privateKeyECData.suffix(65) + Server.privateKeyECData.subdata(in: 36..<68)
            guard let secKey = SecKeyCreateWithData(privateKeyData as CFData, attributes, &cfError) else {
                throw cfError!.takeRetainedValue()
            }
            
            let signatureInfo = SignatureInfo.with { signatureInfo in
                signatureInfo.verificationKeyVersion = "v1"
                signatureInfo.verificationKeyID = "310"
                signatureInfo.signatureAlgorithm = "SHA256withECDSA"
            }
            
            // In a real implementation, the file at remoteURL would be downloaded from a server
            // This sample generates and saves a binary and signature pair of files based on the locally stored diagnosis keys
            let export = TemporaryExposureKeyExport.with { export in
                export.batchNum = 1
                export.batchSize = 1
                export.region = "310"
                export.signatureInfos = [signatureInfo]
                export.keys = diagnosisKeys.shuffled().map { diagnosisKey in
                    TemporaryExposureKey.with { temporaryExposureKey in
                        temporaryExposureKey.keyData = diagnosisKey.keyData
                        temporaryExposureKey.transmissionRiskLevel = Int32(diagnosisKey.transmissionRiskLevel)
                        temporaryExposureKey.rollingStartIntervalNumber = Int32(diagnosisKey.rollingStartNumber)
                        temporaryExposureKey.rollingPeriod = Int32(diagnosisKey.rollingPeriod)
                    }
                }
            }
            
            let exportData = "EK Export v1    ".data(using: .utf8)! + (try export.serializedData())
            
            var exportHash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = exportData.withUnsafeBytes { exportDataBuffer in
                exportHash.withUnsafeMutableBytes { exportHashBuffer in
                    CC_SHA256(exportDataBuffer.baseAddress, CC_LONG(exportDataBuffer.count), exportHashBuffer.bindMemory(to: UInt8.self).baseAddress)
                }
            }
            
            guard let signedHash = SecKeyCreateSignature(secKey, .ecdsaSignatureDigestX962SHA256, exportHash as CFData, &cfError) as Data? else {
                throw cfError!.takeRetainedValue()
            }
            
            let tekSignatureList = TEKSignatureList.with { tekSignatureList in
                tekSignatureList.signatures = [TEKSignature.with { tekSignature in
                    tekSignature.signatureInfo = signatureInfo
                    tekSignature.signature = signedHash
                    tekSignature.batchNum = 1
                    tekSignature.batchSize = 1
                }]
            }
            
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            
            let localBinURL = cachesDirectory.appendingPathComponent(remoteURL.lastPathComponent + ".bin")
            try exportData.write(to: localBinURL)
            
            let localSigURL = cachesDirectory.appendingPathComponent(remoteURL.lastPathComponent + ".sig")
            try tekSignatureList.serializedData().write(to: localSigURL)
            
            completion(.success([localBinURL, localSigURL]))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteDiagnosisKeyFile(at localURLs: [URL]) throws {
        for localURL in localURLs {
            try FileManager.default.removeItem(at: localURL)
        }
    }
    
    func getExposureConfiguration(completion: (Result<ENExposureConfiguration, Error>) -> Void) {
        
        let dataFromServer = """
        {
        "immediateDurationWeight":100,
        "nearDurationWeight":100,
        "mediumDurationWeight":100,
        "otherDurationWeight":100,
        "infectiousnessForDaysSinceOnsetOfSymptoms":{
            "unknown":1,
            "-14":1,
            "-13":1,
            "-12":1,
            "-11":1,
            "-10":1,
            "-9":1,
            "-8":1,
            "-7":1,
            "-6":1,
            "-5":1,
            "-4":1,
            "-3":1,
            "-2":1,
            "-1":1,
            "0":1,
            "1":1,
            "2":1,
            "3":1,
            "4":1,
            "5":1,
            "6":1,
            "7":1,
            "8":1,
            "9":1,
            "10":1,
            "11":1,
            "12":1,
            "13":1,
            "14":1
        },
        "infectiousnessStandardWeight":100,
        "infectiousnessHighWeight":100,
        "reportTypeConfirmedTestWeight":100,
        "reportTypeConfirmedClinicalDiagnosisWeight":100,
        "reportTypeSelfReportedWeight":100,
        "reportTypeRecursiveWeight":100,
        "reportTypeNoneMap":1,
        "minimumRiskScore":0,
        "attenuationDurationThresholds":[50, 70],
        "attenuationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "daysSinceLastExposureLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "durationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "transmissionRiskLevelValues":[1, 2, 3, 4, 5, 6, 7, 8]
        }
        """.data(using: .utf8)!
        
        do {
            let codableExposureConfiguration = try JSONDecoder().decode(CodableExposureConfiguration.self, from: dataFromServer)
            let exposureConfiguration = ENExposureConfiguration()
            if ENManagerIsAvailable() {
                exposureConfiguration.immediateDurationWeight = codableExposureConfiguration.immediateDurationWeight
                exposureConfiguration.nearDurationWeight = codableExposureConfiguration.nearDurationWeight
                exposureConfiguration.mediumDurationWeight = codableExposureConfiguration.mediumDurationWeight
                exposureConfiguration.otherDurationWeight = codableExposureConfiguration.otherDurationWeight
                var infectiousnessForDaysSinceOnsetOfSymptoms = [Int: Int]()
                for (stringDay, infectiousness) in codableExposureConfiguration.infectiousnessForDaysSinceOnsetOfSymptoms {
                    if stringDay == "unknown" {
                        if #available(iOS 14.0, *) {
                            infectiousnessForDaysSinceOnsetOfSymptoms[ENDaysSinceOnsetOfSymptomsUnknown] = infectiousness
                        } else {
                            // ENDaysSinceOnsetOfSymptomsUnknown is not available
                            // in earlier versions of iOS; use an equivalent value
                            infectiousnessForDaysSinceOnsetOfSymptoms[NSIntegerMax] = infectiousness
                        }
                    } else if let day = Int(stringDay) {
                        infectiousnessForDaysSinceOnsetOfSymptoms[day] = infectiousness
                    }
                }
                exposureConfiguration.infectiousnessForDaysSinceOnsetOfSymptoms = infectiousnessForDaysSinceOnsetOfSymptoms as [NSNumber: NSNumber]
                exposureConfiguration.infectiousnessStandardWeight = codableExposureConfiguration.infectiousnessStandardWeight
                exposureConfiguration.infectiousnessHighWeight = codableExposureConfiguration.infectiousnessHighWeight
                exposureConfiguration.reportTypeConfirmedTestWeight = codableExposureConfiguration.reportTypeConfirmedTestWeight
                exposureConfiguration.reportTypeConfirmedClinicalDiagnosisWeight = codableExposureConfiguration.reportTypeConfirmedClinicalDiagnosisWeight
                exposureConfiguration.reportTypeSelfReportedWeight = codableExposureConfiguration.reportTypeSelfReportedWeight
                exposureConfiguration.reportTypeRecursiveWeight = codableExposureConfiguration.reportTypeRecursiveWeight
                if let reportTypeNoneMap = ENDiagnosisReportType(rawValue: UInt32(codableExposureConfiguration.reportTypeNoneMap)) {
                    exposureConfiguration.reportTypeNoneMap = reportTypeNoneMap
                }
            }
            exposureConfiguration.minimumRiskScore = codableExposureConfiguration.minimumRiskScore
            exposureConfiguration.attenuationLevelValues = codableExposureConfiguration.attenuationLevelValues as [NSNumber]
            exposureConfiguration.daysSinceLastExposureLevelValues = codableExposureConfiguration.daysSinceLastExposureLevelValues as [NSNumber]
            exposureConfiguration.durationLevelValues = codableExposureConfiguration.durationLevelValues as [NSNumber]
            exposureConfiguration.transmissionRiskLevelValues = codableExposureConfiguration.transmissionRiskLevelValues as [NSNumber]
            exposureConfiguration.metadata = ["attenuationDurationThresholds": codableExposureConfiguration.attenuationDurationThresholds]
            completion(.success(exposureConfiguration))
        } catch {
            completion(.failure(error))
        }
    }
    
    func verifyUniqueTestIdentifier(_ identifier: String, completion: (Result<Bool, Error>) -> Void) {
        
        // In a real implementation, this identifer would be validated on a server
        completion(.success(identifier == "000000"))
    }
}
