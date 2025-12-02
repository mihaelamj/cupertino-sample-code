/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the service object that dispatches stylus events to the system.
*/

#include <os/log.h>
#include <DriverKit/IOUserServer.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/OSCollections.h>
#include <HIDDriverKit/HIDDriverKit.h>

#include "HIDStylusDriver.h"

struct HIDStylusDriver_IVars
{
    OSArray *elements;
    
    struct {
        OSArray *collections;
    } digitizer;
};

#define _elements   ivars->elements
#define _digitizer  ivars->digitizer

/* init()
*
* Initializes the object by allocating memory for its instance variables.
*/
bool HIDStylusDriver::init()
{
    if (!super::init()) {
        return false;
    }
    
    ivars = IONewZero(HIDStylusDriver_IVars, 1);
    if (!ivars) {
        return false;
    }
    
exit:
    return true;
}

/* free()
*
* Releases the memory for the object's instance variables.
*/
void HIDStylusDriver::free()
{
    if (ivars) {
        OSSafeReleaseNULL(_elements);
        OSSafeReleaseNULL(_digitizer.collections);
    }
    
    IOSafeDeleteNULL(ivars, HIDStylusDriver_IVars, 1);
    super::free();
}

/* Start
*
* Starts the service by fetching and parsing the IOHIDElement objects
*  that the parent event service provides. These elements contain the
*  information from the device's most recent input report. If any elements
*  contain stylus data, this method registers the service with
*  the system, which allows it to handle future input reports for this device.
*/
/// - Tag: Start
kern_return_t
IMPL(HIDStylusDriver, Start)
{
    kern_return_t ret;
    
    ret = Start(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess) {
        Stop(provider, SUPERDISPATCH);
        return ret;
    }

    os_log(OS_LOG_DEFAULT, "Hello World");
    
    _elements = getElements();
    if (!_elements) {
        os_log(OS_LOG_DEFAULT, "Failed to get elements");
        Stop(provider, SUPERDISPATCH);
        return kIOReturnError;
    }
    
    _elements->retain();
    
    if (!parseElements(_elements)) {
        os_log(OS_LOG_DEFAULT, "No supported elements found");
        Stop(provider, SUPERDISPATCH);
        return kIOReturnUnsupported;
    }
    
    RegisterService();
    
    return ret;
}

/* parseElements
*
* This method parses the specified array of IOHIDElement elements, looking for
*  elements that contain stylus data. If it finds any, it returns true;
*  otherwise, it returns false.
*/
bool HIDStylusDriver::parseElements(OSArray *elements)
{
    bool result = false;
    
    for (unsigned int i = 0; i < elements->getCount(); i++) {
        IOHIDElement *element = NULL;
        
        element = OSDynamicCast(IOHIDElement, elements->getObject(i));
        
        if (!element) {
            continue;
        }
        
        if (element->getType() == kIOHIDElementTypeCollection ||
            !element->getUsage()) {
            continue;
        }
        
        if (parseDigitizerElement(element)) {
            result = true;
        }
    }
    
    return result;
}

/* parseDigitizerElement
*
* This method examines the element to determine if it contains
*  stylus-related digitizer data, returning true if it does. The method
*  also saves a reference to the element in the object's instance
*  variables.
*/
/// - Tag: parseDigitizerElement
bool HIDStylusDriver::parseDigitizerElement(IOHIDElement *element)
{
    bool result = false;
    IOHIDElement *parent = element;
    IOHIDDigitizerCollection *collection = NULL;
    
    if (element->getType() > kIOHIDElementTypeInput_ScanCodes) {
        return false;
    }
    
    // Find the top-level collection element.
    while ((parent = parent->getParentElement())) {
        IOHIDElementCollectionType collectionType = parent->getCollectionType();
        uint32_t usagePage = parent->getUsagePage();
        uint32_t usage = parent->getUsage();
        
        if (usagePage != kHIDPage_Digitizer) {
            continue;
        }
        
        if (collectionType == kIOHIDElementCollectionTypeLogical ||
            collectionType == kIOHIDElementCollectionTypePhysical) {
            if (usage >= kHIDUsage_Dig_Stylus &&
                usage <= kHIDUsage_Dig_GestureCharacter) {
                break;
            }
        } else if (collectionType == kIOHIDElementCollectionTypeApplication) {
            if (usage >= kHIDUsage_Dig_Digitizer &&
                usage <= kHIDUsage_Dig_DeviceConfiguration) {
                break;
            }
        }
    }
    
    // Ignore elements that aren't in an appropriate collection.
    if (!parent) {
        return false;
    }
    
    switch (element->getUsagePage()) {
        case kHIDPage_GenericDesktop:
            switch (element->getUsage()) {
                case kHIDUsage_GD_X:
                case kHIDUsage_GD_Y:
                case kHIDUsage_GD_Z:
                    if (element->getFlags() & kIOHIDElementFlagsRelativeMask) {
                        return false;
                    }
                    break;
            }
            break;
    }
    
    if (!_digitizer.collections) {
        _digitizer.collections = OSArray::withCapacity(4);
        if (!_digitizer.collections) {
            return false;
        }
    }
    
    // Find the collection the element belongs to.
    for (unsigned int i = 0; i < _digitizer.collections->getCount(); i++) {
        IOHIDDigitizerCollection *tmp = OSDynamicCast(IOHIDDigitizerCollection,
                                                      _digitizer.collections->getObject(i));
        
        if (!tmp) {
            continue;
        }
        
        if (tmp->getParentCollection() == parent) {
            collection = tmp;
            break;
        }
    }
    
    // If an appropriate parent collection wasn't found, create one.
    if (!collection) {
        IOHIDDigitizerCollectionType type = kIOHIDDigitizerCollectionTypeStylus;
        
        switch (parent->getUsage()) {
            case kHIDUsage_Dig_Puck:
                type = kIOHIDDigitizerCollectionTypePuck;
                break;
            case kHIDUsage_Dig_Finger:
            case kHIDUsage_Dig_TouchScreen:
            case kHIDUsage_Dig_TouchPad:
                type = kIOHIDDigitizerCollectionTypeFinger;
                break;
            default:
                break;
        }
        
        // Create the new collection object.
        collection = IOHIDDigitizerCollection::withType(type, parent);
        if (!collection) {
            return false;
        }
        
        _digitizer.collections->setObject(collection);
        collection->release();
    }
    
    // Add the element to the collection.
    collection->addElement(element);
    result = true;
    
exit:
    return result;
}

/* handleReport
*
* This overridden method receives the input data from the device, and
*  hands it off to the handleDigitizerReport method for processing.
*/
/// - Tag: handleReport
void HIDStylusDriver::handleReport(uint64_t timestamp,
                                   uint8_t *report __unused,
                                   uint32_t reportLength __unused,
                                   IOHIDReportType type,
                                   uint32_t reportID)
{
    handleDigitizerReport(timestamp, reportID);
}

/* printStylus
*
* Writes the specified stylus data to the system log.
*/
static void printStylus(IOHIDDigitizerStylusData *data)
{
    os_log(OS_LOG_DEFAULT, "dispatch stylus: id: %d x: %d y: %d range: %d tip: %d barrel: %d invert: %d erase: %d tp: %d tx: %d ty: %d tw: %d tc: %d pc: %d rc: %d",
           data->identifier, data->x, data->y, data->inRange, data->tip, data->barrelSwitch, data->invert, data->eraser, data->tipPressure,
           data->tiltX, data->tiltY, data->twist, data->tipChanged, data->positionChanged, data->rangeChanged);
}

/* handleDigitizerReport
*
* This method processes the subset of elements that contain stylus data.
*  By the time the driver calls this method, the parent class has already
*  updated the IOHIDElement objects that you retrieved in your Start method.
*  As a result, each element contains data from the most recent input report.
*/
/// - Tag: handleDigitizerReport
void HIDStylusDriver::handleDigitizerReport(uint64_t timestamp,
                                           uint32_t reportID)
{
    if (!_digitizer.collections) {
        return;
    }
    
    for (unsigned int i = 0; i < _digitizer.collections->getCount(); i++) {
        IOHIDDigitizerCollection *collection = OSDynamicCast(IOHIDDigitizerCollection,
                                                             _digitizer.collections->getObject(i));
        IOHIDDigitizerStylusData *stylusData = NULL;
        
        if (!collection) {
            continue;
        }
        
        stylusData = createStylusDataForDigitizerCollection(collection,
                                                            timestamp,
                                                            reportID);
        
        if (stylusData) {
            printStylus(stylusData);
            dispatchDigitizerStylusEvent(timestamp, stylusData);
            IOFree(stylusData, sizeof(IOHIDDigitizerStylusData));
        }
    }
}

/* createStylusDataForDigitizerCollection
*
* This method looks for updated data in the elements of the digitizer
*  collection. If it finds any updated values, it allocates and returns
*  an IOHIDDigitizerStylusData structure with that information and
*  returns true; otherwise, the method returns false.
*/
/// - Tag: createStylusDataForDigitizerCollection
IOHIDDigitizerStylusData *HIDStylusDriver::createStylusDataForDigitizerCollection(
                                        IOHIDDigitizerCollection *collection,
                                        uint64_t timestamp,
                                        uint32_t reportID)
{
    IOHIDDigitizerStylusData *stylusData = NULL;
    OSArray *elements = collection->getElements();
    bool handled = false;
    
    if (!elements) {
        return NULL;
    }
    
    stylusData = (IOHIDDigitizerStylusData *)IOMallocZero(sizeof(IOHIDDigitizerStylusData));
    
    if (!stylusData) {
        return NULL;
    }
    
    // Iterate over all of the elements in the collection.
    for (unsigned int i = 0; i < elements->getCount(); i++) {
        IOHIDElement *element = OSDynamicCast(IOHIDElement, elements->getObject(i));
        uint64_t elementTimeStamp;
        uint32_t usagePage, usage, value, logicalDiff;
        bool elementIsCurrent;
        IOFixed scaledValue = 0;
        
        if (!element) {
            continue;
        }
        
        // Gather information from the element.
        elementTimeStamp = element->getTimeStamp();
        elementIsCurrent = (element->getReportID() == reportID) && (timestamp == elementTimeStamp);
        usagePage = element->getUsagePage();
        usage = element->getUsage();
        value = element->getValue(0);
        logicalDiff = element->getLogicalMax() - element->getLogicalMin();
        
        // Compute the logical value for the current element, as needed.
        if (logicalDiff) {
            scaledValue = (IOFixed)(((value - element->getLogicalMin()) << 16) / logicalDiff);
        }
        
        // Update the stylus data structure. Update the handled variable at
        // each step to indicate whether the data is new.
        switch (usagePage) {
            case kHIDPage_GenericDesktop:
                switch (usage) {
                    case kHIDUsage_GD_X:
                        stylusData->x = scaledValue;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_GD_Y:
                        stylusData->y = scaledValue;
                        handled |= elementIsCurrent;
                        break;
                }
                break;
            case kHIDPage_Digitizer:
                switch (usage) {
                    case kHIDUsage_Dig_ContactIdentifier:
                        stylusData->identifier = value;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_TipSwitch:
                        stylusData->tip = value ? 1 : 0;
                        handled |= (elementIsCurrent | (stylusData->tip != 0));
                        break;
                    case kHIDUsage_Dig_BarrelSwitch:
                        stylusData->barrelSwitch = value ? 1 : 0;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_Eraser:
                        stylusData->eraser = value ? 1 : 0;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_InRange:
                        stylusData->inRange = value ? 1 : 0;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_BarrelPressure:
                        stylusData->barrelPressure = scaledValue;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_TipPressure:
                        stylusData->tipPressure = scaledValue;
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_XTilt:
                        stylusData->tiltX = element->getScaledFixedValue(kIOHIDValueScaleTypePhysical);
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_YTilt:
                        stylusData->tiltY = element->getScaledFixedValue(kIOHIDValueScaleTypePhysical);
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_Twist:
                        stylusData->twist = element->getScaledFixedValue(kIOHIDValueScaleTypePhysical);
                        handled |= elementIsCurrent;
                        break;
                    case kHIDUsage_Dig_Invert:
                        stylusData->invert = value ? 1 : 0;
                        handled |= elementIsCurrent;
                        break;
                    default:
                        break;
                }
                break;
        }
    }
    
    // If no data changed, return NULL.
    if (!handled) {
        IOFree(stylusData, sizeof(IOHIDDigitizerStylusData));
        return NULL;
    }
    
    // Otherwise, finish updating the stylus data structure.
    if (stylusData->tip != collection->getTouch()) {
        stylusData->tipChanged = 1;
    }
    
    if (stylusData->inRange) {
        if (collection->getX() != stylusData->x ||
            collection->getY() != stylusData->y) {
            stylusData->positionChanged = 1;
        }
    }
    
    if (stylusData->inRange != collection->getInRange()) {
        stylusData->rangeChanged = 1;
    }
    
    // Update the collection with the new data too.
    collection->setTouch(stylusData->tip);
    collection->setX(stylusData->x);
    collection->setY(stylusData->y);
    collection->setInRange(stylusData->inRange);
    
exit:
    return stylusData;
}
