/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that generates an itinerary by streaming the response output in its partially generated form.
*/

import FoundationModels
import Observation

@Observable
@MainActor
final class ItineraryPlanner {
    private(set) var itinerary: Itinerary.PartiallyGenerated?
    private(set) var pointOfInterestTool: FindPointsOfInterestTool
    private var session: LanguageModelSession
    
    var error: Error?
    let landmark: Landmark

    init(landmark: Landmark) {
        self.landmark = landmark
        Logging.general.log("The landmark is... \(landmark.name)")
        let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
        self.session = LanguageModelSession(
            tools: [pointOfInterestTool],
            instructions: Instructions {
                "Your job is to create an itinerary for the person."
                
                "Each day needs an activity, hotel and restaurant."
                
                """
                Always use the findPointsOfInterest tool to find businesses \
                and activities in \(landmark.name), especially hotels \
                and restaurants.
                
                The point of interest categories may include:
                """
                FindPointsOfInterestTool.categories
                
                """
                Here is a description of \(landmark.name) for your reference \
                when considering what activities to generate:
                """
                landmark.description
            }
        )
        self.pointOfInterestTool = pointOfInterestTool
    }

    func suggestItinerary(dayCount: Int) async throws {
        let stream = session.streamResponse(
            generating: Itinerary.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(sampling: .greedy)
        ) {
            "Generate a \(dayCount)-day itinerary to \(landmark.name)."
            
            "Give it a fun title and description."
            
            "Here is an example, but don't copy it:"
            Itinerary.exampleTripToJapan
        }

        for try await partialResponse in stream {
            itinerary = partialResponse.content
        }
    }

    func prewarm() {
        session.prewarm()
    }
}

extension Itinerary {
    static let exampleTripToJapan = Itinerary(
        title: "Onsen Trip to Japan",
        destinationName: "Mt. Fuji",
        description: "Sushi, hot springs, and ryokan with a toddler!",
        rationale:
            """
            You are traveling with a child, so climbing Mt. Fuji is probably not an option, \
            but there is lots to do around Kawaguchiko Lake, including Fujikyu. \
            I recommend staying in a ryokan because you love hotsprings.
            """,
        days: [
            DayPlan(
                title: "Sushi and Shopping Near Kawaguchiko",
                subtitle: "Spend your final day enjoying sushi and souvenir shopping.",
                destination: "Kawaguchiko Lake",
                activities: [
                    Activity(
                        type: .foodAndDining,
                        title: "The Restaurant serving Sushi",
                        description: "Visit an authentic sushi restaurant for lunch."
                    ),
                    Activity(
                        type: .shopping,
                        title: "The Plaza",
                        description: "Enjoy souvenir shopping at various shops."
                    ),
                    Activity(
                        type: .sightseeing,
                        title: "The Beautiful Cherry Blossom Park",
                        description: "Admire the beautiful cherry blossom trees in the park."
                    ),
                    Activity(
                        type: .hotelAndLodging,
                        title: "The Hotel",
                        description:
                            "Spend one final evening in the hotspring before heading home."
                    )
                ]
            )
        ]
    )
}
