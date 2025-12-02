/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The constants for identifiers that both the user client and the driver use.
*/

#ifndef SimpleAudioDriverKeys_h
#define SimpleAudioDriverKeys_h

#define kSimpleAudioDriverClassName "SimpleAudioDriver"
#define kSimpleAudioDriverDeviceUID "SimpleAudioDevice-UID"

#define kSimpleAudioDriverCustomPropertySelector 'sadc'
#define kSimpleAudioDriverCustomPropertyQualifier0 "Qualifier-0"
#define kSimpleAudioDriverCustomPropertyQualifier1 "Qualifier-1"
#define kSimpleAudioDriverCustomPropertyDataValue0 "Default-0"
#define kSimpleAudioDriverCustomPropertyDataValue1 "Default-1"

enum SimpleAudioDriverExternalMethod
{
    SimpleAudioDriverExternalMethod_Open, // No arguments.
    SimpleAudioDriverExternalMethod_Close, // No arguments.
    SimpleAudioDriverExternalMethod_ToggleDataSource, // No argument. This switches between data source selection.
    SimpleAudioDriverExternalMethod_TestConfigChange // No arguments. This switches between sample rates and exercises the config change mechanism.
};

#endif /* SimpleAudioDriverKeys_h */
