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
const VECTOR3_12_ENCODE_SCALE = Core.VECTOR3_12_ENCODE_SCALE
const VECTOR3_12_DECODE_SCALE = Core.VECTOR3_12_DECODE_SCALE

return table.freeze{
	write = function(self: Codec, writer: Writer, value: Vector3): ()
		if typeof(value) ~= "Vector3" then
			error(`Serdes.Vector3_12 expected Vector3, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + 12 > writer.capacity then
			resize(writer, 12)
		end

		const x = value.X
		const y = value.Y
		const z = value.Z

		if x ~= x or y ~= y or z ~= z or x == INF or x == -INF or y == INF or y == -INF or z == INF or z == -INF then
			error("Serdes.Vector3_12 expected finite Vector3", 3)
		end
		
		writer.offset = offset + 12
		
		const iy = (((y < VECTOR3_MIN and VECTOR3_MIN or y > VECTOR3_MAX and VECTOR3_MAX or y) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1
		const iz = (((z < VECTOR3_MIN and VECTOR3_MIN or z > VECTOR3_MAX and VECTOR3_MAX or z) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1

		buffer.writeu32(writer.buffer, offset, (((x < VECTOR3_MIN and VECTOR3_MIN or x > VECTOR3_MAX and VECTOR3_MAX or x) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1 + bit32.lshift(bit32.extract(iy, 0, 2), 30))
		buffer.writeu32(writer.buffer, offset + 4, bit32.rshift(iy, 2) + bit32.lshift(bit32.extract(iz, 0, 4), 28))
		buffer.writeu32(writer.buffer, offset + 8, bit32.rshift(iz, 4))
	end,

	read = function(self: Codec, reader: Reader): Vector3
		const offset = reader.offset
		const reader_buffer = reader.buffer

		if offset + 12 > reader.length then
			error(`Serdes read out of bounds. Needed 12 bytes at offset {offset}.`, 3)
		end
		
		reader.offset = offset + 12

		const word0 = buffer.readu32(reader_buffer, offset)
		const word1 = buffer.readu32(reader_buffer, offset + 4)

		return Vector3.new(
			VECTOR3_MIN + bit32.extract(word0, 0, 30) * VECTOR3_12_DECODE_SCALE,
			VECTOR3_MIN + (bit32.rshift(word0, 30) + bit32.lshift(bit32.extract(word1, 0, 28), 2)) * VECTOR3_12_DECODE_SCALE,
			VECTOR3_MIN + (bit32.rshift(word1, 28) + bit32.lshift(buffer.readu32(reader_buffer, offset + 8), 4)) * VECTOR3_12_DECODE_SCALE
		)
	end,

	min_size = 12,
	size = 12,
} :: Codec
