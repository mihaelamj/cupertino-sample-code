# Slothy: Integrating SlothCreator into an App

Integrate SlothCreator into an iOS app for creating and caring 
for custom sloths.

@Metadata {
    @CallToAction(
        purpose: link,
        url: "https://example.com/slothy-repository")
    @PageKind(sampleCode)
    @PageImage(
        purpose: card, 
        source: "slothy-card", 
        alt: "Two screenshots showing the Slothy app. The first screenshot shows a sloth map and the second screenshot shows a sloth power picker.")
}

## Overview

This sample creates _Slothy_, an app for creating
and caring for custom sloths.

@Video(poster: "slothy-hero-poster", source: "slothy-hero", alt: "An animated video showing two screens in the Slothy app. The first screenshot shows a sloth map and the second screenshot shows a sloth power picker.")

@Row {
    @Column(size: 2) {
        First, you customize your sloth by picking its 
        ``Sloth/power-swift.property``.
        The power of your sloth influences its abilities and how well
        they cope in their environment. The app displays a picker view
        that showcases the available powers and previews your sloth
        for the selected power.
    }
    
    @Column {
        ![A screenshot of the power picker user interface with four powers displayed – ice, fire, wind, and lightning](slothy-powerPicker)
    }
}



@Row {
    @Column {
        ![A screenshot of the sloth status user interface that indicates the the amount of sleep, fun, and exercise a given sloth is in need of.](slothy-status)
    }
    
    @Column(size: 2) {
        Once you've customized your sloth, it's ready to 
        ready to thrive. You'll find that sloths will 
        happily munch on a leaf, but may not be as 
        receptive to working out. Use the activity picker 
        to send some encouragement.
    }
}

### Localization

Slothy also showcases SlothCreator's localized content.
The name of powers and food are presented in the device's 
current locale. Take a look at a few examples.

@TabNavigator {
    @Tab("English") {
        ![Two screenshots showing the Slothy app rendering with English language content. The first screenshot shows a sloth map and the second screenshot shows a sloth power picker.](slothy-localization_eng)
    }
    
    @Tab("Chinese") {
        ![Two screenshots showing the Slothy app rendering with Chinese language content. The first screenshot shows a sloth map and the second screenshot shows a sloth power picker.](slothy-localization_zh)
    }
    
    @Tab("Spanish") {
        ![Two screenshots showing the Slothy app rendering with Spanish language content. The first screenshot shows a sloth map and the second screenshot shows a sloth power picker.](slothy-localization_es)
    }
}
