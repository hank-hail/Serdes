--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<Vector3>

const INF = Core.INF
const VECTOR3_MIN = Core.VECTOR3_MIN
const VECTOR3_MAX = Core.VECTOR3_MAX
const VECTOR3_8_ENCODE_SCALE = Core.VECTOR3_8_ENCODE_SCALE
const VECTOR3_8_DECODE_SCALE = Core.VECTOR3_8_DECODE_SCALE

return table.freeze{
	write = function(self: Codec, writer: Writer, value: Vector3): ()
		if typeof(value) ~= "Vector3" then
			error(`Serdes.Vector3_8 expected Vector3, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + 8 > writer.capacity then
			resize(writer, 8)
		end

		const x = value.X
		const y = value.Y
		const z = value.Z

		if x ~= x or y ~= y or z ~= z or x == INF or x == -INF or y == INF or y == -INF or z == INF or z == -INF then
			error("Serdes.Vector3_8 expected finite Vector3", 3)
		end
		
		writer.offset = offset + 8

		const iy = (((y < VECTOR3_MIN and VECTOR3_MIN or y > VECTOR3_MAX and VECTOR3_MAX or y) - VECTOR3_MIN) * VECTOR3_8_ENCODE_SCALE + 0.5) // 1

		buffer.writeu32(writer.buffer, offset, (((x < VECTOR3_MIN and VECTOR3_MIN or x > VECTOR3_MAX and VECTOR3_MAX or x) - VECTOR3_MIN) * VECTOR3_8_ENCODE_SCALE + 0.5) // 1 + bit32.lshift(bit32.extract(iy, 0, 11), 21))
		buffer.writeu32(writer.buffer, offset + 4, bit32.rshift(iy, 11) + bit32.lshift((((z < VECTOR3_MIN and VECTOR3_MIN or z > VECTOR3_MAX and VECTOR3_MAX or z) - VECTOR3_MIN) * VECTOR3_8_ENCODE_SCALE + 0.5) // 1, 10))
	end,

	read = function(self: Codec, reader: Reader): Vector3
		const offset = reader.offset

		if offset + 8 > reader.length then
			error(`Serdes read out of bounds. Needed 8 bytes at offset {offset}.`, 3)
		end

		const word0 = buffer.readu32(reader.buffer, offset)
		const word1 = buffer.readu32(reader.buffer, offset + 4)

		reader.offset = offset + 8

		return Vector3.new(
			VECTOR3_MIN + bit32.extract(word0, 0, 21) * VECTOR3_8_DECODE_SCALE,
			VECTOR3_MIN + (bit32.rshift(word0, 21) + bit32.lshift(bit32.extract(word1, 0, 10), 11)) * VECTOR3_8_DECODE_SCALE,
			VECTOR3_MIN + bit32.extract(word1, 10, 21) * VECTOR3_8_DECODE_SCALE
		)
	end,

	min_size = 8,
	size = 8,
} :: Codec
