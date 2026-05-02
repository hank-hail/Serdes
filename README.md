# Serdes

Compact binary serialization/desiralization for Roblox Luau.

## Usage

```luau
const Serdes = require'@game/ReplicatedStorage/Serdes'

type Data = {
	is_alive: boolean,
	level: number,
	health: number,
	position: Vector3,
}

const player_datac: Serdes.Object<Data> = Serdes.object{
	Serdes.field("is_alive", Serdes.bool),
	Serdes.field("level", Serdes.u8),
	Serdes.field("health", Serdes.u8),
	Serdes.field("position", Serdes.Vector3_8),
}

const encoded = player_data:encode{
	is_alive = true,
	level = 25,
	health = 200,
	position = Vector3.new(100, 50, -25),
}

const decoded = player_codec:decode(encoded)

print(decoded)
print(buffer.len(encoded))
````

## Direct Codec Usage

```luau
const encoded = Serdes.encode(Serdes.u32, 123456)
const decoded = Serdes.decode(Serdes.u32, encoded)

print(decoded)
```

## Included Codecs

```luau
Serdes.bool
Serdes.u8
Serdes.i8
Serdes.u16
Serdes.i16
Serdes.u32
Serdes.i32
Serdes.f32
Serdes.f64
Serdes.string
Serdes.Vector3_8
Serdes.Vector3_12
Serdes.CFrame_12
Serdes.CFrame_17
```
