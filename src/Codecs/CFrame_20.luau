--!strict
--!native

const Core = require'./Core'

const resize = Core.resize
const matrix_to_quat = Core.matrix_to_quat
const choose_smallest_three = Core.choose_smallest_three
const quat_to_cframe = Core.quat_to_cframe

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<CFrame>

const INF = Core.INF
const VECTOR3_MIN = Core.VECTOR3_MIN
const VECTOR3_MAX = Core.VECTOR3_MAX
const CFRAME_20_BYTES = Core.CFRAME_20_BYTES
const VECTOR3_12_ENCODE_SCALE = Core.VECTOR3_12_ENCODE_SCALE
const VECTOR3_12_DECODE_SCALE = Core.VECTOR3_12_DECODE_SCALE

const INV_SQRT2 = Core.INV_SQRT2
const CFRAME_20_ROT_ENCODE_SCALE = Core.CFRAME_20_ROT_ENCODE_SCALE
const CFRAME_20_ROT_DECODE_SCALE = Core.CFRAME_20_ROT_DECODE_SCALE


return table.freeze{
	write = function(self: Codec, writer: Writer, value: CFrame): ()
		if typeof(value) ~= "CFrame" then
			error(`Serdes.CFrame_20 expected CFrame, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + CFRAME_20_BYTES > writer.capacity then
			resize(writer, CFRAME_20_BYTES)
		end

		local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()

		if px ~= px or py ~= py or pz ~= pz or px == INF or px == -INF or py == INF or py == -INF or pz == INF or pz == -INF then
			error("Serdes.CFrame_20 expected finite CFrame position", 3)
		end
		
		writer.offset = offset + CFRAME_20_BYTES

		const iy = (((py < VECTOR3_MIN and VECTOR3_MIN or py > VECTOR3_MAX and VECTOR3_MAX or py) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1
		const iz = (((pz < VECTOR3_MIN and VECTOR3_MIN or pz > VECTOR3_MAX and VECTOR3_MAX or pz) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1

		local index, a, b, c = choose_smallest_three(matrix_to_quat(r00, r01, r02, r10, r11, r12, r20, r21, r22))

		const qa = (((a < -INV_SQRT2 and -INV_SQRT2 or a > INV_SQRT2 and INV_SQRT2 or a) + INV_SQRT2) * CFRAME_20_ROT_ENCODE_SCALE + 0.5) // 1
		const qb = (((b < -INV_SQRT2 and -INV_SQRT2 or b > INV_SQRT2 and INV_SQRT2 or b) + INV_SQRT2) * CFRAME_20_ROT_ENCODE_SCALE + 0.5) // 1

		buffer.writeu32(
			writer.buffer,
			offset,
			(((px < VECTOR3_MIN and VECTOR3_MIN or px > VECTOR3_MAX and VECTOR3_MAX or px) - VECTOR3_MIN) * VECTOR3_12_ENCODE_SCALE + 0.5) // 1 + bit32.lshift(bit32.extract(iy, 0, 2), 30)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 4,
			bit32.rshift(iy, 2) + bit32.lshift(bit32.extract(iz, 0, 4), 28)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 8,
			bit32.rshift(iz, 4)
				+ bit32.lshift(index, 26)
				+ bit32.lshift(bit32.extract(qa, 0, 4), 28)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 12,
			bit32.rshift(qa, 4) + bit32.lshift(bit32.extract(qb, 0, 14), 18)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 16,
			bit32.rshift(qb, 14) + bit32.lshift((((c < -INV_SQRT2 and -INV_SQRT2 or c > INV_SQRT2 and INV_SQRT2 or c) + INV_SQRT2) * CFRAME_20_ROT_ENCODE_SCALE + 0.5) // 1, 8)
		)
	end,

	read = function(self: Codec, reader: Reader): CFrame
		const offset = reader.offset
		const reader_buffer = reader.buffer

		if offset + CFRAME_20_BYTES > reader.length then
			error(`Serdes read out of bounds. Needed {CFRAME_20_BYTES} bytes at offset {offset}.`, 3)
		end
		
		reader.offset = offset + CFRAME_20_BYTES

		const word0 = buffer.readu32(reader_buffer, offset)
		const word1 = buffer.readu32(reader_buffer, offset + 4)
		const word2 = buffer.readu32(reader_buffer, offset + 8)
		const word3 = buffer.readu32(reader_buffer, offset + 12)
		const word4 = buffer.readu32(reader_buffer, offset + 16)

		const ix = bit32.extract(word0, 0, 30)
		const iy = bit32.rshift(word0, 30) + bit32.lshift(bit32.extract(word1, 0, 28), 2)
		const iz = bit32.rshift(word1, 28) + bit32.lshift(bit32.extract(word2, 0, 26), 4)

		const index = bit32.extract(word2, 26, 2)
		const a = (bit32.rshift(word2, 28) + bit32.lshift(bit32.extract(word3, 0, 18), 4)) * CFRAME_20_ROT_DECODE_SCALE - INV_SQRT2
		const b = (bit32.rshift(word3, 18) + bit32.lshift(bit32.extract(word4, 0, 8), 14)) * CFRAME_20_ROT_DECODE_SCALE - INV_SQRT2
		const c = bit32.extract(word4, 8, 22) * CFRAME_20_ROT_DECODE_SCALE - INV_SQRT2

		const omitted_squared = 1.0 - (a * a + b * b + c * c)
		const omitted = omitted_squared > 0 and math.sqrt(omitted_squared) or 0

		if index == 0 then
			return quat_to_cframe(VECTOR3_MIN + ix * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iy * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iz * VECTOR3_12_DECODE_SCALE, omitted, a, b, c)
		elseif index == 1 then
			return quat_to_cframe(VECTOR3_MIN + ix * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iy * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iz * VECTOR3_12_DECODE_SCALE, a, omitted, b, c)
		elseif index == 2 then
			return quat_to_cframe(VECTOR3_MIN + ix * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iy * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iz * VECTOR3_12_DECODE_SCALE, a, b, omitted, c)
		end

		return quat_to_cframe(VECTOR3_MIN + ix * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iy * VECTOR3_12_DECODE_SCALE, VECTOR3_MIN + iz * VECTOR3_12_DECODE_SCALE, a, b, c, omitted)
	end,

	min_size = CFRAME_20_BYTES,
	size = CFRAME_20_BYTES,
} :: Codec
