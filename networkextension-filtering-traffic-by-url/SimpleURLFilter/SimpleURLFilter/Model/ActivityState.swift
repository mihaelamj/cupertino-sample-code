/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ActivityState represents the various transitory states of various activities performed by the application.
 This is used to give feedback on the progress and status of actions to the user interface.
*/

import Foundation

public enum ActivityState {
    case idle
    case configurationLoadStart, configurationLoadEnd, configurationLoadEmpty, configurationLoadFailed
    case configurationSaveStart, configurationSaveEnd, configurationSaveFailed
    case configurationRemoveStart, configurationRemoveEnd, configurationRemoveFailed
    case configurationEnableStart, configurationEnableEnd, configurationEnableFailed
    case configurationDisableStart, configurationDisableEnd, configurationDisableFailed
    case pirCacheResetStart, pirCacheResetEnd, pirCacheResetFailed
    case pirParametersRefreshStart, pirParametersRefreshEnd, pirParametersRefreshFailed
}
