--!strict
--!native

const Codecs = require'@self/Codecs'

export type Array<T> = {T}

export type Reader = Codecs.Reader
export type Writer = Codecs.Writer

export type Codec<T> = Codecs.Codec<T>

export type Field<T> = {
	name: string,
	codec: Codec<T>,
}

export type Object<T> = Codec<T> & {
	fields: Array<Field<any>>,

	min_size: number,
	size: number?,

	encode: (self: Object<T>, value: T) -> buffer,
	decode: (self: Object<T>, data: buffer) -> T,
}

export type Serdes = Codecs.Codecs & {
	field: <T>(name: string, codec: Codec<T>) -> Field<T>,
	object: <T>(fields: Array<Field<any>>) -> Object<T>,

	encode: <T>(codec: Codec<T>, value: T) -> buffer,
	decode: <T>(codec: Codec<T>, data: buffer) -> T,
}

const DEFAULT_CAPACITY = 64

const Serdes = {} :: Serdes

for name, value in Codecs do
	Serdes[name] = value
end

const Object = {}
Object.__index = Object

const function create_writer(capacity: number?): Writer
	const actual_capacity = if capacity == nil then DEFAULT_CAPACITY else capacity

	return {
		buffer = buffer.create(actual_capacity),
		offset = 0,
		capacity = actual_capacity,
	}
end

const function create_reader(data: buffer): Reader
	return {
		buffer = data,
		offset = 0,
		length = buffer.len(data),
	}
end

const function finish_writer(writer: Writer): buffer
	if writer.offset == writer.capacity then
		return writer.buffer
	end

	const result = buffer.create(writer.offset)
	buffer.copy(result, 0, writer.buffer, 0, writer.offset)

	return result
end

const function get_initial_capacity(codec: Codec<any>): number?
	if codec.size ~= nil then
		return codec.size
	end

	if codec.min_size ~= nil and codec.min_size > DEFAULT_CAPACITY then
		return codec.min_size
	end

	return nil
end

function Object.write<T>(self: Object<T>, writer: Writer, value: T): ()
	if type(value) ~= "table" then
		error(`Serdes.object expected table, got {type(value)} instead`, 3)
	end

	const fields = self.fields
	const dictionary = value :: any

	for _, field in fields do
		field.codec:write(writer, dictionary[field.name])
	end
end

function Object.read<T>(self: Object<T>, reader: Reader): T
	const fields = self.fields
	const result = {}

	for _, field in fields do
		result[field.name] = field.codec:read(reader)
	end

	return result :: any
end

function Object.encode<T>(self: Object<T>, value: T): buffer
	const writer = create_writer(get_initial_capacity(self))

	self:write(writer, value)

	return finish_writer(writer)
end

function Object.decode<T>(self: Object<T>, data: buffer): T
	if typeof(data) ~= "buffer" then
		error(`Serdes.decode expected buffer, got {typeof(data)} instead`, 3)
	end

	const reader = create_reader(data)
	const result = self:read(reader)

	if reader.offset ~= reader.length then
		error(`Serdes.decode left {reader.length - reader.offset} unread bytes`, 3)
	end

	return result
end

table.freeze(Object)

function Serdes.field<T>(name: string, codec: Codec<T>): Field<T>
	if type(name) ~= "string" then
		error(`Serdes.field expected string name, got {type(name)} instead`, 3)
	end

	return {
		name = name,
		codec = codec,
	}
end

function Serdes.object<T>(fields: Array<Field<any>>): Object<T>
	local min_size = 0
	local size = 0
	local fixed = true

	for _, field in fields do
		const codec = field.codec

		min_size += codec.min_size or 0

		if codec.size == nil then
			fixed = false
		else
			size += codec.size
		end
	end

	return setmetatable({
		fields = fields,
		min_size = min_size,
		size = if fixed then size else nil,
	}, Object) :: any
end

function Serdes.encode<T>(codec: Codec<T>, value: T): buffer
	const writer = create_writer(get_initial_capacity(codec))

	codec:write(writer, value)

	return finish_writer(writer)
end

function Serdes.decode<T>(codec: Codec<T>, data: buffer): T
	if typeof(data) ~= "buffer" then
		error(`Serdes.decode expected buffer, got {typeof(data)} instead`, 3)
	end

	const reader = create_reader(data)
	const result = codec:read(reader)

	if reader.offset ~= reader.length then
		error(`Serdes.decode left {reader.length - reader.offset} unread bytes`, 3)
	end

	return result
end

return table.freeze(Serdes) :: Serdes
