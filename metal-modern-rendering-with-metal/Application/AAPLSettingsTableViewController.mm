/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the controller managing the table view UI.
*/

#import "AAPLSettingsTableViewController.h"

#import <vector>

#if TARGET_OS_IPHONE

static NSString *ButtonCellIdentifier   = @"buttonCell";
static NSString *ToggleCellIdentifier   = @"toggleCell";
static NSString *SliderCellIdentifier   = @"sliderCell";
static NSString *ComboCellIdentifier    = @"comboCell";

typedef NS_ENUM(uint32_t, AAPLWidgetType)
{
    AAPLWidgetTypeButton,
    AAPLWidgetTypeSwitch,
    AAPLWidgetTypeSlider,
    AAPLWidgetTypeComboRow,
};

struct AAPLWidget
{
    AAPLWidgetType type;
    NSString* label;
    SettingsCallback callback;
    union
    {
        bool*   boolValue;
        float*  floatValue;
        int*    intValue;
    };
    float min;
    float max;
};

struct AAPLSection
{
    bool                    isCombo;
    NSString*               label;
    NSArray<NSString*>*     options;
    uint*                   value;
    SettingsCallback        callback;

    std::vector<AAPLWidget> widgets;
};

@implementation AAPLSettingsTableViewController
{
    std::vector<AAPLSection> _sections;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)addWidget:(const AAPLWidget&)widget
{
    if(_sections.empty() || _sections.back().isCombo)
    {
        AAPLSection section;
        section.isCombo = false;
        section.label   = @" ";
        section.options = nil;
        section.value   = nil;

        _sections.push_back(section);
    }

    _sections.back().widgets.push_back(widget);
}

- (void)addButton:(NSString*)label callback:(nullable SettingsCallback)callback
{
    AAPLWidget widget;
    widget.type      = AAPLWidgetTypeButton;
    widget.label     = label;
    widget.callback  = callback;

    [self addWidget:widget];
}

- (void)addToggle:(NSString*)label value:(bool*)value callback:(SettingsCallback)callback
{
    AAPLWidget widget;
    widget.type      = AAPLWidgetTypeSwitch;
    widget.label     = label;
    widget.boolValue = value;
    widget.callback  = callback;

    [self addWidget:widget];
}

- (void)addSlider:(NSString*)label value:(float*)value min:(float)min max:(float)max
{
    AAPLWidget widget;
    widget.type         = AAPLWidgetTypeSlider;
    widget.label        = label;
    widget.floatValue   = value;
    widget.min          = min;
    widget.max          = max;

    [self addWidget:widget];
}

- (void)addCombo:(NSString*)label options:(NSArray<NSString*>*)options value:(uint*)value callback:(SettingsCallback)callback
{
    AAPLSection section;
    section.isCombo     = true;
    section.label       = label;
    section.options     = options;
    section.value       = value;
    section.callback    = callback;

    _sections.push_back(section);
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.size();
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex
{
    return _sections[sectionIndex].label;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    const AAPLSection& section = _sections[sectionIndex];

    if(section.isCombo)
        return section.options.count;

    return section.widgets.size();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const AAPLSection& section = _sections[indexPath.section];

    AAPLWidgetType type = AAPLWidgetTypeComboRow;

    if(!section.isCombo)
    {
        const AAPLWidget& widget = section.widgets[indexPath.row];
        type = widget.type;
    }

    NSString *cellIdentifier = ComboCellIdentifier;

    if(type == AAPLWidgetTypeSlider)
        cellIdentifier = SliderCellIdentifier;
    else if(type == AAPLWidgetTypeSwitch)
        cellIdentifier = ToggleCellIdentifier;
    else if(type == AAPLWidgetTypeButton)
        cellIdentifier = ButtonCellIdentifier;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle         = UITableViewCellSelectionStyleNone;
        cell.backgroundColor        = [UIColor clearColor];
        cell.textLabel.textColor    = [UIColor whiteColor];

        if(type == AAPLWidgetTypeSlider)
        {
            const AAPLWidget& widget = section.widgets[indexPath.row];

            UISlider* cellSlider    = [[UISlider alloc] init];
            cellSlider.minimumValue = widget.min;
            cellSlider.maximumValue = widget.max;

            [cellSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

            cell.accessoryView = cellSlider;
        }
        else if(type == AAPLWidgetTypeSwitch)
        {
            UISwitch* cellSwitch = [[UISwitch alloc] init];
            cellSwitch.onTintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]; //[UIColor systemBlueColor];

            [cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];

            cell.accessoryView = cellSwitch;
        }
    }

    if(section.isCombo)
    {
        cell.textLabel.text = section.options[indexPath.row];

        if(indexPath.row == *section.value)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        const AAPLWidget& widget = section.widgets[indexPath.row];

        if(widget.type == AAPLWidgetTypeSlider)
        {
            UISlider* cellSlider    = (UISlider*)cell.accessoryView;
            cellSlider.value        = *widget.floatValue;
        }
        else if(widget.type == AAPLWidgetTypeSwitch)
        {
            UISwitch* cellSwitch    = (UISwitch*)cell.accessoryView;
            cellSwitch.on           = *widget.boolValue;
        }

        cell.textLabel.text = widget.label;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const AAPLSection& section = _sections[indexPath.section];

    if(!section.isCombo)
    {
        const AAPLWidget& widget = section.widgets[indexPath.row];

        if(widget.type == AAPLWidgetTypeButton && widget.callback)
            widget.callback();

        return;
    }

    // clear all checkmarks in combo section
    for (int row = 0; row < [tableView numberOfRowsInSection:indexPath.section]; row++)
    {
        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:cellPath];

        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    *section.value = (uint)indexPath.row;

    if(section.callback)
        section.callback();
}

- (IBAction)switchValueChanged:(UISwitch*)sender
{
    UITableView *tableView = (UITableView*)self.view;
    NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell*)sender.superview];

    const AAPLSection& section = _sections[indexPath.section];
    const AAPLWidget& widget = section.widgets[indexPath.row];

    *widget.boolValue = sender.on;

    if(widget.callback)
        widget.callback();
}

- (IBAction)sliderValueChanged:(UISlider*)sender
{
    UITableView *tableView = (UITableView*)self.view;
    NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell*)sender.superview];

    const AAPLSection& section = _sections[indexPath.section];
    const AAPLWidget& widget = section.widgets[indexPath.row];

    *widget.floatValue = sender.value;

    if(widget.callback)
        widget.callback();
}

- (void)reloadData
{
    [(UITableView*)self.view reloadData];
}

@end

#endif
