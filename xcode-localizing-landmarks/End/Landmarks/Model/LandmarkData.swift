/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's sample landmark data.
*/

import Foundation
extension Landmark {
    /// The app's sample landmark data.
    @MainActor static let exampleData = [
        Landmark(
            id: 1001,
            name: LocalizedStringResource("Sahara Desert", table: "LandmarkData"),
            continent: "Africa",
            description: LocalizedStringResource("""
The sprawling Sahara Desert spans more than 3.5 million square miles and is the largest hot desert in the world. \
Covering much of northern Africa, it reaches three major bodies of water: \
the Atlantic Ocean in the west, the Red Sea in the east, and the Mediterranean Sea to the north. \
To the south is the Sahei region. The Sahara’s harsh environment is characterized by vast sand dunes, arid plains, and rocky plateaus. \
The tallest sand dune is located in the Erg Chebbi region of southeastern Morocco and reaches a height of roughly 330 feet. \
The desert plays an important role in shaping climate patterns and ecological systems.

Formed over the course of millions of years and dating back to the Precambrian era, the Sahara was once a lush, \
verdant landscape with lakes and rivers. Over many years, wind erosion has sculpted towering cliffs, rock arches, \
deep canyons and many striking and picturesque landforms. \
Beneath a surface composed of gravel plains and sand seas lies vast underground aquifers that store ancient water, \
hidden remnants of a time when the Sahara was a much more hospitable place.

While the Sahara experiences extreme temperatures and has scarce rainfall, \
it supports a variety of plant and animal life that have adapted to the harsh conditions. \
The sparse vegetation includes drought-tolerant varieties such as desert grasses such as \
Lovegrass that can store water in their roots and help prevent soil erosion. \
Other vegetation includes Acacia trees, date palms, and olive trees. \
Animal life has also adapted to be able to endure the extreme heat and extended periods of time with little or no water. \
Fennec foxes, camels, addax, and scorpions are some examples of the species found in the Sahara. \
Many animals have made nocturnal adaptations in order to remain hidden during the high daytime temperatures. \
Many migratory birds pass through the region and take advantage of seasonal water sources and oases.
""", table: "LandmarkData"),
            latitude: 23.900_13,
            longitude: 10.335_69,
            span: 40.0,
            placeID: "IC6C65CA81B4B2772",
            totalArea: .init(value: 9_200_200, unit: .squareKilometers),
            elevation: .fixed(.init(value: 300, unit: .meters)),
            location: LocalizedStringResource("Africa", table: "LandmarkData"),
            badge: .saharaDesert,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1002,
            name: LocalizedStringResource("Serengeti", table: "LandmarkData"),
            continent: "Africa",
            description: LocalizedStringResource("""
Located in northern Tanzania and southwestern Kenya, the Serengeti is a mix of riparian forests, \
acacia woodlands, and grasslands that covers nearly 12,000 square miles. With open plains that stretch seemingly forever, \
it creates a breathtaking backdrop for one of the most spectacular wildlife events on Earth: the awe-inspiring Great Migration.

Volcano activity from the nearby Ngorongoro Highlands shaped much of the region, depositing nutrient-rich soil \
as a result of past eruptions. The Serengeti sits atop Precambrian rock formations and supports vast herds of \
herbivores with abundant grasses. \
The Mara and Grumeti rivers carve their way through he plains, providing crucial water supplies to sustain wildlife year-round.

The Serengeti is home to one of Africa’s highest concentrations of large mammal species, including elephants, \
giraffes, hyenas, lions, and zebras. Every year, more than a million wildebeest make a circular migration across the Serengeti Plains, \
following seasonal rains. Their grazing and trampling of grass allow new grasses to grow, while their wast helps fertilize the soil.
""", table: "LandmarkData"),
            latitude: -2.454_69,
            longitude: 34.881_59,
            span: 10.0,
            placeID: "IB3A0184A4D301279",
            totalArea: .init(value: 14_763, unit: .squareKilometers),
            elevation: .fixed(.init(value: 920, unit: .meters)),
            location: LocalizedStringResource("Tanzania", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1003,
            name: LocalizedStringResource("Deadvlei", table: "LandmarkData"),
            continent: "Africa",
            description: LocalizedStringResource("""
An otherworldly landscape of contrasting bleached white claypan ground, blackened camel thorn trees, \
and fiery red-orange dunes, Deadvlei is located in Namibia’s Namib-Naukluft National Park. Over 900 years ago, \
Deadvlei was a thriving marshland, but dried up as shifting sand dunes cut off its water supply. \
Despite it’s remote location, Deadvlei has become a renown tourist attraction, especially for photographers, \
enticing visitors from around the world to witness it’s unique beauty.

Home to some of highest dunes in the world — some reaching up to 1100 feet — are sculpted into graceful ever-changing shapes. \
The vibrant hue of the dunes is a result of the iron oxide content in the sand and shift with the sunlight.

Due to extreme arid conditions, the dead camel trees don’t decompose, leaving behind ghostly reminders of a vibrant ecosystem \
dating back a millennia. Even with the harsh environment, some plant species such as nara melons and salsola have \
adapted and survive off the morning mist and rare rainfall.
""", table: "LandmarkData"),
            latitude: -24.7629,
            longitude: 15.294_29,
            span: 10.0,
            placeID: "IBD2966F32E73D261",
            totalArea: nil,
            elevation: .fixed(.init(value: 550, unit: .meters)),
            location: LocalizedStringResource("Namibia", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1004,
            name: LocalizedStringResource("Grand Canyon", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
When you look down from the rim of the Grand Canyon, you are looking at a visual story of Earth’s ancient past. \
Carved over millions of years by the Colorado River, the canyon stretches 277 miles in length, spans widths up to 18 miles, \
and reaches depths of over a mile (6,093 feet). \
The vibrant house of the canyon, ranging from deep reds and oranges to subtle shades of purple, it is an iconic natural wonder.

The geological story that the canyon tells spans nearly two billion years. Vishnu Schist at the bottom of the Inner Gorge \
is estimated to be 1.7 billion years old. The much younger Kaibab Limestone formation on the rim is the \
canyon’s top most rock layer, dating back a mere 270 million years. \
Between these two extremes, wind and water erosion have sculpted stunning cliffs, mesas, and buttes to create an intricate \
landscape of canyons within canyons. Every year, the seasonal variations in the Colorado River’s flow continue to carve the \
canyons deeper and deeper.

Just as the geology story shifts with the altitude change, the plant and animal diversity changes dramatically. \
Flora ranges from desert species such as cacti and junipers to high-elevation forests of spruce fir or ponderosa pine, \
groundsels, yarrow, and lupine. Bighorn sheep, mule deer, and the elusive mountain lion are just some of the \
wildlife species that make their home in this ecological treasure.
""", table: "LandmarkData"),
            latitude: 36.219_04,
            longitude: -113.160_96,
            span: 10.0,
            placeID: "I55488B3D1D9B2D4B",
            totalArea: nil,
            elevation: .closedRange(low: .init(value: 800, unit: .meters), high: .init(value: 2000, unit: .meters)),
            location: LocalizedStringResource("Arizona, United States", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1005,
            name: LocalizedStringResource("Niagara Falls", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Niagara Falls is comprised of three separate falls, Horseshoe Falls, American Falls, and Bridal Veil Falls. \
It lies at the border between Canada and the United States. \
The millions of gallons of water that plunge over its edge originates from Lake Erie in the Great Lakes. \
The flow of water produces a roaring cascade, fills the air with mist, and creates vibrant rainbows. \
It is one of the most famous and powerful waterfalls in the world.

The Falls began to form at the end of the last Ice Age, \
taking more than 12,000 years to fully develop. \
The process continues today as the flow of water continues to erode sedimentary layers of rock to shape and reshape the landscape. \
Preservation work has been done to preserve the Falls, and the volume of water has reduced due to diversion for hydroelectric power, \
which generates nearly 4.9 million kilowatts of power.

A dynamic ecosystem exists around the Falls. Fish life thrives in the Niagara River, including species such as bass and sturgeon. \
Gulls, bald eagles, and peregrine falcons are some of the avian wildlife that can be seen flying above the Falls, \
while lush vegetation grows along the riverbanks.
""", table: "LandmarkData"),
            latitude: 43.077_92,
            longitude: -79.074_01,
            span: 4.0,
            placeID: "I433E22BD30C61C40",
            totalArea: nil,
            elevation: .fixed(.init(value: 108, unit: .meters)),
            location: LocalizedStringResource("Ontario, Canada and New York, United States", table: "LandmarkData"),
            badge: .niagaraFalls,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1006,
            name: LocalizedStringResource("Joshua Tree", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Spanning more than 1,200 square miles, the Joshua Tree National Park is located in Southern California not far from Palm Springs. \
The park spans both the Mojave and Colorado deserts and is most known for the rugged rock formations and the spiky, twisted Joshua trees. \
The two deserts have distinct characteristics. On the western side of the park, \
the higher and cooler Mojave is a high desert ecosystem while the eastern side’s Colorado is a low desert climate.

Ancient volcanic activity, erosion, and tectonic fault movement shaped the park’s dramatic landscape. \
Surreal formations of massive granite boulders, rock hills (known as inselbergs), hidden canyons, \
and the unique Joshua trees create an otherworldly beauty.

Despite the harsh desert climates, a variety of resilient wildlife and plant life can be found. \
Larger mammals such as coyote, desert bighorn sheep, mountain lion often burrow or stay in caves during the hot day time hours, \
becoming more active at night. Ancient bristlecone pines, creosote bush, and ephemeral spring wildflowers \
are some of the more than 1,000 species of plant found Joshua Tree.
""", table: "LandmarkData"),
            latitude: 33.887_52,
            longitude: -115.808_26,
            span: 10.0,
            placeID: "I34674B3D3B032AA2",
            totalArea: .init(value: 3218, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 160, unit: .meters), high: .init(value: 1800, unit: .meters)),
            location: LocalizedStringResource(
                "California, United States",
                table: "LandmarkData"
            )
        ),
        
        Landmark(
            id: 1007,
            name: LocalizedStringResource("Rocky Mountains", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Stretching 3,000 miles from northwest Canada to southwest United States, the Rocky Mountains are the setting for \
some of North America’s most stunning scenery. With soaring peaks, jagged summits, pastoral alpine meadows, \
dense forests, and crystal clear lakes, the Rockies are home to a wide range of flora and fauna. \
The mountain habitats support a wide range wildlife including wolves, elk, moose, bighorn sheep, grizzly bears, and wolverines. \
The variety of plants found in the Rocky Mountains is similarly diverse including over 900 species of wildflowers \
and conifers such as pine, spruce, and fir. Deciduous trees, known for their brilliant colorful autumn leaves \
contribute to some of the most biologically diverse habitats in the Rocky Mountain National Park. \
All of these ecological elements and waterways provide an important habitat for North America migratory birds.

The geological history of the Rocky Mountains dates back approximately 60 to 70 million years when several tectonic \
plates began shifting under the North American plate. The result was a long, broad belt of mountains running along western North America. \
The dramatic peaks and valleys we see today were further formed by tectonic activity and erosion by glaciers. \
The majority of the highest peaks are found in Colorado. Numerous public parks protect much of the mountain range, \
providing tourists plenty of year-round activities.
""", table: "LandmarkData"),
            latitude: 47.625_96,
            longitude: -112.998_72,
            span: 16.0,
            placeID: "IBD757C9B53C92D9E",
            totalArea: .init(value: 780_000, unit: .squareKilometers),
            elevation: .openRange(high: .init(value: 4400, unit: .meters)),
            location: LocalizedStringResource("North America", table: "LandmarkData"),
            badge: .rockyMountains,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: false,
                .readDescription: false,
                .findNature: false,
                .drawSketch: false
            ])
        ),
        
        Landmark(
            id: 1008,
            name: LocalizedStringResource("Monument Valley", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Presenting a spectacular display of towering sandstone buttes, vibrant red rock formations, and expansive open plains, \
Monument Valley is an iconic landscape of the Colorado Plateau, located near the Arizona-Utah border. \
The stratified buttes rise dramatically from the valley floor reaching heights up to 1,000 feet. \
Formed by rivers, wind, and ice, the valley is comprised largely of siltstone and sand deposits. \
Softer material eroded away, leaving the massive sandstone buttes that remain today.

Vegetation in Monument Valley is sparse but beautiful. Contributing to an interesting palette, plants like purple sage \
complement the red rock formations with splashes of purple flowers and white or gray leaves. \
Rabbitbrush brings in yellow flowers and green leaves. \
Mojave yucca plants have fine hairs and a wax coating to trap moisture and reflect sunlight to help it survive.

Animal life is diverse, with large mammals like the mountain lions, coyotes, and jackrabbits. \
Reptiles include lizards such as the long-nose leopard lizard as well as iguanas and various snakes. \
With watchful eyes soaring above all of this are red-tailed hawks, tree sparrows, and more.
""", table: "LandmarkData"),
            latitude: 36.874,
            longitude: -110.348,
            span: 10.0,
            placeID: "IAB1F0D2360FAAD29",
            totalArea: .init(value: 370, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 1500, unit: .meters), high: .init(value: 1800, unit: .meters)),
            location: LocalizedStringResource("Utah and Arizona, United States", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1009,
            name: LocalizedStringResource("Muir Woods", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Frequently shrouded in coastal marine layer fog from the Pacific Ocean, Muir Woods National Monument is an old-growth redwood forest. \
Located 12 miles north of San Francisco, covering 558 acres, and containing 6 miles of gorgeous hiking trails, \
Muir Woods is part of the Golden Gate National Recreation Area.

The moist environment promotes a rich community of interesting plants, organized into three layers. \
The lowest layer is the herbaceous layer and is full of shade-loving life. The next layer is the understory, \
where shrubs and tress such as the California bay and tan oak grow. \
Providing shelter and platforms for various tree-dwelling species is the topmost layer, or canopy.

Within the multilayered, dense habitat, it’s easy for wildlife to remain unseen, making the forest sometimes appear empty. \
Looks, however, are deceiving. Muir Wood hosts over 50 species of birds including spotted owls and pileated woodpeckers. \
Mammals range in size from the small American shrew mole to the black-tailed mule deer. \
Most mammals are nocturnal or burrowing animals, contributing to the sense of emptiness in the forest.
""", table: "LandmarkData"),
            latitude: 37.8922,
            longitude: -122.574_82,
            span: 2.0,
            placeID: "I907589547EB05261",
            totalArea: .init(value: 2, unit: .squareKilometers),
            elevation: .fixed(.init(value: 166, unit: .meters)),
            location: LocalizedStringResource("California, United States", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1010,
            name: LocalizedStringResource("Amazon Rainforest", table: "LandmarkData"),
            continent: "South America",
            description: LocalizedStringResource("""
As a member of an elite club of natural landmarks that cover more than one percent of the planet’s surface, \
the Amazon rainforest covers approximately 2.3 million square miles. \
The majority of the rainforest is in Brazil, but it spills over into other neighboring countries including Peru, Bolivia, and Columbia. \
While it’s common to think of a rainforest as being sparsely populated, an estimated 30 million people live in the Amazon.

With the highest diversity of plant life on Earth, the Amazon may contain as many as 80,000 plant species. \
An astounding 75 percent of those species are endemic to the area, not being found anywhere else, including 16,000 trees species. \
Other unique species include giant Amazon water lily, rubber trees, and cacao trees.

Hundreds of animal species are also found in the rainforest. Notably, the Amazon is one of Earth’s last refuges for jaguars, \
harpy eagles, and pink river dolphins. Many other large animals live in the Amazon including cougars, the black caiman, \
and even the Caquetá titi monkey which purrs like a cat.
""", table: "LandmarkData"),
            latitude: -3.508_79,
            longitude: -62.808_02,
            span: 30.0,
            placeID: "I76A1045FB9294971",
            totalArea: .init(value: 6_000_000, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 20, unit: .meters), high: .init(value: 60, unit: .meters)),
            location: LocalizedStringResource("South America", table: "LandmarkData"),
            badge: .amazonRainforest,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: false,
                .readDescription: false,
                .findNature: false,
                .drawSketch: false
            ])
        ),
        
        Landmark(
            id: 1011,
            name: LocalizedStringResource("Lençóis Maranhenses", table: "LandmarkData"),
            continent: "South America",
            description: LocalizedStringResource("""
Lençóis Maranhenses National Park covers approximately 380,000 acres on the northeastern coast of Brazil, \
including 43 miles of coastline along the Atlantic Ocean. \
The interior of the park is composed of rolling sand dunes that reach as high as 130 feet.

Despite looking like a desert environment, the area receives about 47 inches of rain per year. \
During the rainy seasons, the spaces between the dune peaks fill with freshwater lagoons.

With desert-like but wet locale, a unique and diverse ecosystem has evolved. \
Vegetation adapted to coastal and freshwater environments such as Restinga and mangrove are found here. \
Four endangered species of animals reside in the park: the scarlet ibis, neotropical otter, oncilla, and West Indian manatee. \
The wolf fish is a unique species that burrows into wet mud during the dry season.
""", table: "LandmarkData"),
            latitude: -2.578_12,
            longitude: -43.033_45,
            span: 10.0,
            placeID: "I292A37DAC754D6A0",
            totalArea: .init(value: 1550, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 40, unit: .meters)),
            location: LocalizedStringResource("Northeastern Maranhão, Brazil", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1012,
            name: LocalizedStringResource("Uyuni Salt Flat", table: "LandmarkData"),
            continent: "South America",
            description: LocalizedStringResource("""
At an elevation of nearly 12,000 feet above sea level near the crest of the Andes mountain range in southwestern Bolivia, \
the Salar de Uyuni is the world’s largest salt flat. \
Extraordinarily flat, with elevation variation no more than one meter over the nearly 4,000 square mile area, \
the Salar was formed by several prehistoric lakes evaporating over the last 40,000 years. \
The resulting salt crust is several meters thick and rich in lithium.

Despite its prehistoric origin, modern technology has found an important use for the Uyuni. \
Because salt flats are large, stable surfaces, they are ideal for satellite calibration. \
Uyuni is especially well suited for this task due to the lack of industry, long low rain periods, and very clear dry air. \
During the rainy season, the flat turns into a shallow lake with a glass-like surface and becomes the world’s largest natural mirror.

The salt flat has few forms of plant life, which includes the giant cacti, Echinopsis pasacana and Echinopsis tarijensis, \
which tower up to 40 feet over the Uyuni flats. \
Other plants found in Uyuni include pitaya (or dragon fruit), quinoa plants, and queñua bushes.
""", table: "LandmarkData"),
            latitude: -20.133_78,
            longitude: -67.489_14,
            span: 10.0,
            placeID: "ID903C9A78EB0CAAD",
            totalArea: .init(value: 10_582, unit: .squareKilometers),
            elevation: .fixed(.init(value: 3663, unit: .meters)),
            location: LocalizedStringResource("Potosi Department, Bolivia", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1014,
            name: LocalizedStringResource("White Cliffs of Dover", table: "LandmarkData"),
            continent: "Europe",
            description: LocalizedStringResource("""
Standing guard over the narrowest part of the English Channel, the White Cliffs of Dover present \
a striking façade of chalk streaked with accents of black flint. Over millions of years, skeletons of \
tiny algae and other sea creatures settled into the white mud under the sea. \
After these deposits compacted to form chalk, a major mountain building event forced the undersea masses above sea level \
to form the cliffs.

Above the cliffs, a chalk grassland supports many species of wildflowers, butterflies, and birds. \
Orchids, rock samphire, and the unusual oxtongue broomrape are found here. In spring and autumn, \
the rare Adonis blue butterfly can be seen in the grasslands, as can the similar looking chalk hill blue. \
Many migratory birds use the cliffs as their first landing point after crossing the English Channel. \
Peregrine falcons and the skylark are some of the birds that make their homes along the cliffs.
""", table: "LandmarkData"),
            latitude: 51.136_41,
            longitude: 1.363_51,
            span: 4.0,
            placeID: "I77B160572D5A2EB1",
            totalArea: nil,
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 110, unit: .meters)),
            location: LocalizedStringResource("Kent, England", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1015,
            name: LocalizedStringResource("Alps", table: "LandmarkData"),
            continent: "Europe",
            description: LocalizedStringResource("""
Extending nearly 750 miles from Nice, France in the west to Trieste, Italy in the east, the Alps stretch across eight different countries. \
The mountains formed over tens of millions of years as tectonic plates collided, forcing sedimentary rock to rise into mountain peaks. \
Mont Blanc is the tallest mountain in Europe, soaring over 15,700 feet. \
The high altitude and sheer size of the mountains have an effect on the climate in Europe.

Diverse and unique flora has developed in the Alps by adapting to a high-altitude environment. \
The iconic Edelweiss is an alpine flower that thrives in rocky limestone. \
Mountain cranberry and bluets are rare and fragile plants found above treelike. \
Dwarf willow is a resilient plant that does well in places where snow lingers into spring.

Large mammals like the red deer, ibex, Eurasian lynx, and chamois are all found in low and high altitude regions. \
Many rodents such as voles and the Alpine marmot live underground and burrow in the Alps. \
Some reptiles including adders and vipers live near the snow line, but because they cannot tolerate the cold temperatures \
they hibernate underground and soak up warmth on rocky ledges.
""", table: "LandmarkData"),
            latitude: 46.773_67,
            longitude: 10.547_73,
            span: 6.0,
            placeID: "IE380E71D265F97C0",
            totalArea: .init(value: 200_000, unit: .squareKilometers),
            elevation: .openRange(high: .init(value: 4800, unit: .meters)),
            location: LocalizedStringResource("Europe", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1016,
            name: LocalizedStringResource("Mount Fuji", table: "LandmarkData"),
            continent: "Asia",
            description: LocalizedStringResource("""
When seen at a distance, Mount Fuji presents a beautiful, nearly symmetric, often snow-capped profile \
and is Japan’s tallest and most iconic mountain. The volcanic cone rises gracefully up to slightly more than 12,000 feet. \
On clear days, the mountain is visible as far away as Tokyo. \
Despite its seemingly peaceful distant existence, Mount Fuji is an active volcano. \
Its last eruption was in 1707.

Similar to other exceptionally tall mountains, Fuji-san is home to many ecological zones from its base to its summit. \
In the lower elevations, deciduous and coniferous trees such as the Japanese oak and cedars are common. \
As you climb in elevation, the climate becomes harsher and plant life transitions to alpine plants \
and shrubs that have adapted to colder temperatures. At the highest altitudes, a volcanic desert environment exists.

Many mammals and birds are found in the forests on Mount Fuji. \
Black bears live there, although squirrels and fox are more likely to be seen. \
The Japanese serow is a rare and protected species of goat-antelope that roams secretively through dense forests. \
High altitude birds such as the Iwahibari and Hoshigarasu are found above 8,200 feet, while several species of warblers, \
flycatchers, and Ural and scops owls live in lower altitudes.
""", table: "LandmarkData"),
            latitude: 35.360_72,
            longitude: 138.727_44,
            span: 10.0,
            placeID: "I2CC1DF519EDD7ACD",
            totalArea: .init(value: 207, unit: .squareKilometers),
            elevation: .fixed(.init(value: 3776, unit: .meters)),
            location: LocalizedStringResource("Fuji-Hakone-Izu National Park, Japan", table: "LandmarkData"),
            badge: .mountFuji,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1017,
            name: LocalizedStringResource("Wulingyuan", table: "LandmarkData"),
            continent: "Asia",
            description: LocalizedStringResource("""
Featuring more than 3,000 sandstone pillars and peaks, Wulingyuan is a scenic and historic site in China’s Hunan Province. \
Often shrouded in mist, the surreal landscape of pillars surrounded by forests spans over 100 square miles. \
Among the picturesque lakes, rivers, and waterfalls, the site also contains 40 caves and one of the world’s highest natural bridges, \
named Tianqiashengkong.

With plentiful rainfall and dense forests, Wulingyuan has created a good environment for varied animal and plant life. \
Unique species like the clouded leopard, Chinese giant salamander, Asiatic wild dog, and Asiatic black bear live among the forests. \
Other animals include various monkeys — including rhesus monkeys — as well as deer, birds, and reptiles. \
Notable plant species include the dove tree and ginkgo.
""", table: "LandmarkData"),
            latitude: 29.351_06,
            longitude: 110.452_42,
            span: 10.0,
            placeID: "I818C4BA5FE11BDD6",
            totalArea: .init(value: 264, unit: .squareKilometers),
            elevation: .fixed(.init(value: 1050, unit: .meters)),
            location: LocalizedStringResource("Hunan, China", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1018,
            name: LocalizedStringResource("Mount Everest", table: "LandmarkData"),
            continent: "Asia",
            description: LocalizedStringResource("""
In addition to perhaps being the world’s most well-known mountain, Mount Everest is the world’s tallest above sea level. \
With an altitude just over 29,031 feet, the mountain attracts climbers and experienced mountaineers from all over the world. \
Everest’s icy peaks pierce the sky, surrounded by swirling clouds and intensely strong winds.

Geologically, Mount Everest is part of the Himalayan mountain range which is formed by the Eurasian and Indian tectonic plates. \
Movement of these plates began around 50 million years ago and continues to push Everest even higher. \
Layers of metamorphic and sedimentary rock are topped by marine limestone that was once at the bottom of the ocean \
remind us of the Earth’s dynamic history.

Despite the extreme conditions found at the high altitudes on Everest, the mountain is home to a unique high-altitude ecosystem. \
Mosses and lichens can survive the extreme climate along with high altitude plants such as the Himalayan juniper, dwarf rhododendrons, \
and the snow lotus. Animals found in the lower elevations include the Himalayan tahr, snow leopard, Himalayan black bear, and the red panda.
""", table: "LandmarkData"),
            latitude: 27.988_16,
            longitude: 86.9251,
            span: 10.0,
            placeID: "IE16B9C217B9B0DC1",
            totalArea: nil,
            elevation: .fixed(.init(value: 8848, unit: .meters)),
            location: LocalizedStringResource("Koshi Province, Nepal, and Tibet Autonomous Region, China", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1019,
            name: LocalizedStringResource("Great Barrier Reef", table: "LandmarkData"),
            continent: "Australia/Oceania",
            description: LocalizedStringResource("""
Comprised of over 2,900 individual reefs, 900 islands, and spanning a monumental 133,000 square miles, \
the Great Barrier Reef is the world’s largest coral reef system. \
Situated in the Coral Sea just off the coast of Queensland, Australia, the Great Barrier Reef is the world’s largest single \
structure made by living organisms. \
It’s large enough to be seen from space.

The reef system supports a dizzying range of diverse life, including many species that are vulnerable or endangered, \
and some are endemic to the area. \
Dozens of cetaceans including dwarf minke whale, Indo-Pacific humpback dolphin, and the humpback whale live here. \
Clownfish, snapper, and coral trout are just some of the 1,500 fish species found in the waters surrounding the reef.

Sometimes overshadowed by the magnificent aquatic animal life, the Great Barrier Reef is home to over 2,000 species of native plants. \
Seagrass meadows are one of the most fundamental parts of the flora found in the reef system. \
Eelgrass or Turtle grass meadows thrive in the shallow coastal waters and help to maintain the biodiversity, stability, and productivity of the reef.
""", table: "LandmarkData"),
            latitude: -16.7599,
            longitude: 145.978_42,
            span: 16.0,
            placeID: "IF436B51611F3F9D1",
            totalArea: .init(value: 344_400, unit: .squareKilometers),
            elevation: nil,
            location: LocalizedStringResource("Queensland, Australia", table: "LandmarkData"),
            badge: .greatBarrierReef,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1020,
            name: LocalizedStringResource("Yellowstone National Park", table: "LandmarkData"),
            continent: "North America",
            description: LocalizedStringResource("""
Yellowstone was the first national park in the United States, established in 1872. \
The park is well known for the many geothermal features, including more than half the world’s geysers. \
Of these, Old Faithful is the most famous geyser, so named for its dependable schedule of roughly 65 or 91 minutes between eruptions. \
This abundant geothermal activity is thanks to the supervolcano whose caldera forms Yellowstone. \
The caldera was formed during the last eruption, which took place 640,000 years ago.

Besides the geysers, Yellowstone is well known for its wildlife, including herds of bison and elk. \
As for predators, gray wolves are thriving since their reintroduction to the park in the 1990s. \
Other animals that tourists look forward to seeing are black and grizzly bears. Whenever animals are present near the park’s roads, \
dozens of cars park, and camera lenses point out of their windows. \
While the herds and the bears are prized photo subjects of the park’s visitors, it is important to keep a safe distance from them. \
The park also has many popular hiking trails, lakes, and rivers coursing through its canyons.
""", table: "LandmarkData"),
            latitude: 44.6,
            longitude: -110.5,
            span: 4.0,
            placeID: "ICE88191F5D7094D0",
            totalArea: .init(value: 8991, unit: .squareKilometers),
            elevation: .fixed(.init(value: 2470, unit: .meters)),
            location: LocalizedStringResource("Wyoming, United States", table: "LandmarkData")
        ),
        
        Landmark(
            id: 1021,
            name: LocalizedStringResource("South Shetland Islands", table: "LandmarkData"),
            continent: "Antarctica",
            description: LocalizedStringResource("""
The South Shetland Islands consist of 11 major islands and several minor ones, making up more than 1,400 square miles of land area. \
The Antarctic island chain is located in the Drake Passage. Almost all of the land area is permanently covered by glaciers.  \
Active geothermal vents and hot springs provide balance the two contrasting extremes of fire and ice.

Various plants have adapted to the harsh conditions, including two flowering plants — the Antarctic hair grass and Antarctic pearlwort. \
Other examples of adapted plants include mosses, liverworts, lichens, and fungi. \
Notable penguin species include Adélie, Chinstrap, and Gentoo. Crabeater, Leopard, Weddell, and fur seals are some of the island’s other inhabitants.
""", table: "LandmarkData"),
            latitude: -61.794_36,
            longitude: -58.707_03,
            span: 20.0,
            placeID: "I1AAF5FE1DF954A59",
            totalArea: .init(value: 3687, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 2025, unit: .meters)),
            location: LocalizedStringResource("Antarctica", table: "LandmarkData"),
            badge: .southShetlandIslands,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1022,
            name: LocalizedStringResource("Kirkjufell Mountain", table: "LandmarkData"),
            continent: "Europe",
            description: LocalizedStringResource("""
Kirkjufell, or Church Mountain, is a 1,519-ft. high peak situated on the Snæfellsnes peninsula, \
and is one of the most photographed sites in Iceland. \
From varous angles the mountain is thought to resemble an arrow head, or a church. \
Geologically, the hill is not a volcano, but a remnant of the strata that existed before glaciers carved out the surrounding landscape.

The hill is a popular hiking destination, although the trail has steep sections that become dangerously slippery in wet weather. \
Hiring a guide is highly recommended.

Nearby, the Kirkjufellsfoss waterfall offers a spectacular photographic composition of both waterfall and mountain. \
The coastal town of Grundarfjörður, a fishing harbor, offers accommodations and an active arts scene. \
Grundarfjörður is a starting point for hiking trails that offer mesmerizing views of the valleys and mountains of the area. \
A lucky hiker might have an encounter with the arctic fox, white tailed eagle, or an arctic tern.
""", table: "LandmarkData"),
            latitude: 64.941,
            longitude: -23.305,
            span: 2.0,
            placeID: "I4E9DB8B46491DC5E",
            totalArea: nil,
            elevation: .fixed(.init(value: 463, unit: .meters)),
            location: LocalizedStringResource("Iceland", table: "LandmarkData")
        )
    ]
}
