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
const CFRAME_12_BYTES = Core.CFRAME_12_BYTES
const POS_ENCODE_SCALE = Core.POS_ENCODE_SCALE
const POS_DECODE_SCALE = Core.POS_DECODE_SCALE

const INV_SQRT2 = Core.INV_SQRT2
const ROT_ENCODE_SCALE = Core.ROT_ENCODE_SCALE
const ROT_DECODE_SCALE = Core.ROT_DECODE_SCALE


return table.freeze{
	write = function(self: Codec, writer: Writer, value: CFrame): ()
		if typeof(value) ~= "CFrame" then
			error(`Serdes.CFrame_12 expected CFrame, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + CFRAME_12_BYTES > writer.capacity then
			resize(writer, CFRAME_12_BYTES)
		end

		local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()

		if px ~= px or py ~= py or pz ~= pz or px == INF or px == -INF or py == INF or py == -INF or pz == INF or pz == -INF then
			error("Serdes.CFrame_12 expected finite CFrame position", 3)
		end
		
		writer.offset = offset + CFRAME_12_BYTES

		const iy = ((py < VECTOR3_MIN and VECTOR3_MIN or py > VECTOR3_MAX and VECTOR3_MAX or py - VECTOR3_MIN) * POS_ENCODE_SCALE + 0.5) // 1
		const index, a, b, c = choose_smallest_three(matrix_to_quat(r00, r01, r02, r10, r11, r12, r20, r21, r22))
		const qa = (((a < -INV_SQRT2 and -INV_SQRT2 or a > INV_SQRT2 and INV_SQRT2 or a) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1

		buffer.writeu32(
			writer.buffer,
			offset,
			((px < VECTOR3_MIN and VECTOR3_MIN or px > VECTOR3_MAX and VECTOR3_MAX or px - VECTOR3_MIN) * POS_ENCODE_SCALE + 0.5) // 1 + bit32.lshift(bit32.extract(iy, 0, 12), 20)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 4,
			bit32.rshift(iy, 12)
				+ bit32.lshift(((pz < VECTOR3_MIN and VECTOR3_MIN or pz > VECTOR3_MAX and VECTOR3_MAX or pz - VECTOR3_MIN) * POS_ENCODE_SCALE + 0.5) // 1, 8)
				+ bit32.lshift(index, 28)
				+ bit32.lshift(bit32.extract(qa, 0, 2), 30)
		)

		buffer.writeu32(
			writer.buffer,
			offset + 8,
			bit32.rshift(qa, 2)
				+ bit32.lshift((((b < -INV_SQRT2 and -INV_SQRT2 or b > INV_SQRT2 and INV_SQRT2 or b) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1, 9)
				+ bit32.lshift((((c < -INV_SQRT2 and -INV_SQRT2 or c > INV_SQRT2 and INV_SQRT2 or c) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1, 20)
		)
	end,

	read = function(self: Codec, reader: Reader): CFrame
		const offset = reader.offset

		if offset + CFRAME_12_BYTES > reader.length then
			error(`Serdes read out of bounds. Needed {CFRAME_12_BYTES} bytes at offset {offset}.`, 3)
		end
		
		reader.offset = offset + CFRAME_12_BYTES

		const word0 = buffer.readu32(reader.buffer, offset)
		const word1 = buffer.readu32(reader.buffer, offset + 4)
		const word2 = buffer.readu32(reader.buffer, offset + 8)

		const ix = bit32.extract(word0, 0, 20)
		const iy = bit32.rshift(word0, 20) + bit32.lshift(bit32.extract(word1, 0, 8), 12)
		const iz = bit32.extract(word1, 8, 20)

		const index = bit32.extract(word1, 28, 2)
		const a = (bit32.rshift(word1, 30) + bit32.lshift(bit32.extract(word2, 0, 9), 2)) * ROT_DECODE_SCALE - INV_SQRT2
		const b = bit32.extract(word2, 9, 11) * ROT_DECODE_SCALE - INV_SQRT2
		const c = bit32.extract(word2, 20, 11) * ROT_DECODE_SCALE - INV_SQRT2

		const omitted_squared = 1.0 - (a * a + b * b + c * c)
		const omitted = omitted_squared > 0 and math.sqrt(omitted_squared) or 0

		if index == 0 then
			return quat_to_cframe(VECTOR3_MIN + ix * POS_DECODE_SCALE, VECTOR3_MIN + iy * POS_DECODE_SCALE, VECTOR3_MIN + iz * POS_DECODE_SCALE, omitted, a, b, c)
		elseif index == 1 then
			return quat_to_cframe(VECTOR3_MIN + ix * POS_DECODE_SCALE, VECTOR3_MIN + iy * POS_DECODE_SCALE, VECTOR3_MIN + iz * POS_DECODE_SCALE, a, omitted, b, c)
		elseif index == 2 then
			return quat_to_cframe(VECTOR3_MIN + ix * POS_DECODE_SCALE, VECTOR3_MIN + iy * POS_DECODE_SCALE, VECTOR3_MIN + iz * POS_DECODE_SCALE, a, b, omitted, c)
		end

		return quat_to_cframe(VECTOR3_MIN + ix * POS_DECODE_SCALE, VECTOR3_MIN + iy * POS_DECODE_SCALE, VECTOR3_MIN + iz * POS_DECODE_SCALE, a, b, c, omitted)
	end,

	min_size = CFRAME_12_BYTES,
	size = CFRAME_12_BYTES,
} :: Codec
