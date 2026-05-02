--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<string>

const MAX_U32 = Core.MAX_U32

const buffer_writestring = buffer.writestring
const buffer_readstring = buffer.readstring

return table.freeze{
	write = function(self: Codec, writer: Writer, value: string): ()
		if type(value) ~= "string" then
			error(`Serdes.string expected string, got {type(value)} instead`, 3)
		end

		const byte_length = #value

		if byte_length > MAX_U32 then
			error(`Serdes.string expected byte length <= {MAX_U32}, got {byte_length}`, 3)
		end

		local offset = writer.offset

		if byte_length < 0x80 then
			const needed_bytes = byte_length + 1

			if offset + needed_bytes > writer.capacity then
				resize(writer, needed_bytes)
			end

			buffer.writeu8(writer.buffer, offset, byte_length)

			if byte_length > 0 then
				buffer_writestring(writer.buffer, offset + 1, value)
			end

			writer.offset = offset + needed_bytes
			return
		end

		local prefix_size = 5

		if byte_length < 0x4000 then
			prefix_size = 2
		elseif byte_length < 0x200000 then
			prefix_size = 3
		elseif byte_length < 0x10000000 then
			prefix_size = 4
		end

		if offset + prefix_size + byte_length > writer.capacity then
			resize(writer, prefix_size + byte_length)
		end

		local remaining = byte_length

		while remaining >= 0x80 do
			buffer.writeu8(writer.buffer, offset, (remaining % 128) + 128)
			remaining //= 128
			offset += 1
		end

		buffer.writeu8(writer.buffer, offset, remaining)
		offset += 1
		writer.offset = offset + byte_length
		buffer_writestring(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): string
		local offset = reader.offset
		const length = reader.length
		const data = reader.buffer

		if offset + 1 > length then
			error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
		end

		const byte0 = buffer.readu8(data, offset)
		offset += 1

		if byte0 < 0x80 then
			if byte0 == 0 then
				reader.offset = offset
				return ""
			end

			if offset + byte0 > length then
				reader.offset = offset
				error(`Serdes read out of bounds. Needed {byte0} bytes at offset {offset}.`, 3)
			end

			reader.offset = offset + byte0

			return buffer_readstring(data, offset, byte0)
		end

		local byte_length = byte0 % 128
		local multiplier = 128

		for index = 2, 5 do
			if offset + 1 > length then
				reader.offset = offset
				error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
			end

			const byte = buffer.readu8(data, offset)
			offset += 1

			if index == 5 and byte > 15 then
				error("Serdes.string length var_u32 overflowed u32 range.", 3)
			end

			byte_length += (byte % 128) * multiplier

			if byte < 128 then
				if offset + byte_length > length then
					reader.offset = offset
					error(`Serdes read out of bounds. Needed {byte_length} bytes at offset {offset}.`, 3)
				end

				reader.offset = offset + byte_length

				return buffer_readstring(data, offset, byte_length)
			end

			multiplier *= 128
		end

		error("Serdes.string length var_u32 used too many bytes.", 3)
	end,

	min_size = 1,
} :: Codec
