/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The parameter ramp produces a linear ramp to smooth out parameter changes and avoid audio artifacts.
*/

#pragma once

class ParameterRamp {
public:
    // Both current and target values are set to the initial value provided in the constructor.
    explicit ParameterRamp(float value) {
        currentValue = value;
        targetValue = value;
    }
    
    // The ramp length is usually set as a fraction of the sample rate in samples.
    void setRampLength(float length) {
        rampLength = length;
    }
    
    void setTargetValue(float value) {
        // Store the target value, which can be the same as the current value.
        targetValue = value;
        // Update the ramp increment. If current and target values are the same, the ramp increment will be zero.
        rampIncrement = (targetValue - currentValue) / rampLength;
    }
    
    float getNextValue() {
        // If the target value was reached, return it.
        if (currentValue == targetValue)
            return currentValue;
        
        // Otherwise, keep ramping the current value.
        currentValue += rampIncrement;
        
        // If the distance between current and target values is less than the increment, then stop ramping.
        if (fabs(currentValue - targetValue) < fabs(rampIncrement))
            currentValue = targetValue;
        
        return currentValue;
    }
    
private:
    float currentValue = 0;
    float targetValue = 0;
    float rampLength = 0;
    float rampIncrement = 0;
};
