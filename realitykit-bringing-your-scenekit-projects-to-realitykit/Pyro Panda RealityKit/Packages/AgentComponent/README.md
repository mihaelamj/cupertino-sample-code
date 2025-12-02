# AgentComponent

A component that moves a game entity according to a set of goals and
realistic constraints in three-dimensional space.

## Usage

Create two entities to be your agents in a scene, and set one to chase the other.

```swift
let ghost = Entity(named: "ghost")
let snoopy = Entity(named: "snoopy")

let scaryComponent = AgentComponent(
    agentType: .chasing(
        id: snoopy.id,
        distance: .infinity,
        speed: 1.0
    )
)

let fearfulComponent = AgentComponent(
    agentType: .fearing(
        id: ghost.id,
        distance: .infinity,
        speed: 1.0
    )
)

// Set the components to each of the entities.
ghost.components.set(scaryComponent)
snoopy.components.set(fearfulComponent)
```

To limit the movement of entities in the scene, you can set a `centerGoal`.

```swift
let pathPoints: [SIMD3<Float>] = [
    [-1, 0, 1], [1, 0, 1],
    [-1, 0, -1], [1, 0, -1]
]
let stayOnPath = GKPath(
    points: pathPoints.map { $0 / 2 },
    radius: 0.25,
    cyclical: true
)
let centerGoal = GKGoal(toStayOn: stayOnPath, maxPredictionTime: 1)

let fearfulComponent = AgentComponent(
    agentType: .fearing(
        id: ghost.id,
        distance: .infinity,
        speed: 1.0
    ),
    centerGoal: centerGoal
)
```

And to limit the movement to just the xz-axis, use `constraints`.

```swift
let clampY: AgentComponent.PositionConstraints = .position(y: .exact(0))

let fearfulComponent = AgentComponent(
    agentType: .fearing(
        id: ghost.id,
        distance: .infinity,
        speed: 1.0
    ),
    centerGoal: centerGoal,
    constraints: lockYPosition
)
```
