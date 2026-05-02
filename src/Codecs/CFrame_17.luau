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
const INV_SQRT2 = Core.INV_SQRT2
const ROT_ENCODE_SCALE = Core.ROT_ENCODE_SCALE
const ROT_DECODE_SCALE = Core.ROT_DECODE_SCALE

const CFRAME_17_BYTES = Core.CFRAME_12_BYTES

return table.freeze{
	write = function(self: Codec, writer: Writer, value: CFrame): ()
		if typeof(value) ~= "CFrame" then
			error(`Serdes.CFrame_17 expected CFrame, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + CFRAME_17_BYTES > writer.capacity then
			resize(writer, CFRAME_17_BYTES)
		end

		local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()

		if px ~= px or py ~= py or pz ~= pz or px == INF or px == -INF or py == INF or py == -INF or pz == INF or pz == -INF then
			error("Serdes.CFrame_17 expected finite CFrame position", 3)
		end

		const writer_buffer = writer.buffer
		const index, a, b, c = choose_smallest_three(matrix_to_quat(r00, r01, r02, r10, r11, r12, r20, r21, r22))

		const qc = (((c < -INV_SQRT2 and -INV_SQRT2 or c > INV_SQRT2 and INV_SQRT2 or c) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1

		buffer.writef32(writer_buffer, offset, px)
		buffer.writef32(writer_buffer, offset + 4, py)
		buffer.writef32(writer_buffer, offset + 8, pz)

		buffer.writeu32(
			writer_buffer,
			offset + 12,
			index
				+ bit32.lshift((((a < -INV_SQRT2 and -INV_SQRT2 or a > INV_SQRT2 and INV_SQRT2 or a) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1, 2)
				+ bit32.lshift((((b < -INV_SQRT2 and -INV_SQRT2 or b > INV_SQRT2 and INV_SQRT2 or b) + INV_SQRT2) * ROT_ENCODE_SCALE + 0.5) // 1, 13)
				+ bit32.lshift(bit32.extract(qc, 0, 8), 24)
		)

		buffer.writeu8(
			writer_buffer,
			offset + 16,
			bit32.rshift(qc, 8)
		)

		writer.offset = offset + CFRAME_17_BYTES
	end,

	read = function(self: Codec, reader: Reader): CFrame
		const offset = reader.offset

		if offset + CFRAME_17_BYTES > reader.length then
			error(`Serdes read out of bounds. Needed {CFRAME_17_BYTES} bytes at offset {offset}.`, 3)
		end

		const reader_buffer = reader.buffer

		const px = buffer.readf32(reader_buffer, offset)
		const py = buffer.readf32(reader_buffer, offset + 4)
		const pz = buffer.readf32(reader_buffer, offset + 8)

		const word = buffer.readu32(reader_buffer, offset + 12)

		reader.offset = offset + CFRAME_17_BYTES

		const index = bit32.extract(word, 0, 2)
		const a = bit32.extract(word, 2, 11) * ROT_DECODE_SCALE - INV_SQRT2
		const b = bit32.extract(word, 13, 11) * ROT_DECODE_SCALE - INV_SQRT2
		const c = (bit32.extract(word, 24, 8) + bit32.lshift(buffer.readu8(reader_buffer, offset + 16), 8)) * ROT_DECODE_SCALE - INV_SQRT2

		const omitted_squared = 1 - (a * a + b * b + c * c)
		const omitted = omitted_squared > 0 and math.sqrt(omitted_squared) or 0

		if index == 0 then
			return quat_to_cframe(px, py, pz, omitted, a, b, c)
		elseif index == 1 then
			return quat_to_cframe(px, py, pz, a, omitted, b, c)
		elseif index == 2 then
			return quat_to_cframe(px, py, pz, a, b, omitted, c)
		end

		return quat_to_cframe(px, py, pz, a, b, c, omitted)
	end,

	min_size = CFRAME_17_BYTES,
	size = CFRAME_17_BYTES,
} :: Codec
