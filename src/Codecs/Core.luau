--!strict
--!native

type Cursor = {
	buffer: buffer,
	offset: number,
}

export type Writer = Cursor & {
	capacity: number,
}

export type Reader = Cursor & {
	length: number,
}

export type Codec<T> = {
	write: (self: Codec<T>, writer: Writer, value: T) -> (),
	read: (self: Codec<T>, reader: Reader) -> T,
	
	min_size: number,
	size: number?,
}

export type Codecs = {
	bool: Codec<boolean>,

	u8: Codec<number>,
	i8: Codec<number>,

	u16: Codec<number>,
	i16: Codec<number>,

	u32: Codec<number>,
	i32: Codec<number>,

	f32: Codec<number>,
	f64: Codec<number>,

	string: Codec<string>,

	Vector3_8: Codec<Vector3>,
	Vector3_12: Codec<Vector3>,

	CFrame_12: Codec<CFrame>,
	CFrame_20: Codec<CFrame>,

	[string]: Codec<any>,
}

const buffer_create = buffer.create
const buffer_copy = buffer.copy

const Core = {}

Core.MAX_U8 = 255
Core.MIN_I8 = -128
Core.MAX_I8 = 127

Core.MAX_U16 = 65535
Core.MIN_I16 = -32768
Core.MAX_I16 = 32767

Core.MAX_U32 = 4294967295
Core.MIN_I32 = -2147483648
Core.MAX_I32 = 2147483647

Core.F32_MAX = 3.4028234663852886e38
Core.INF = math.huge

Core.VECTOR3_MIN = -100000.0
Core.VECTOR3_MAX = 100000.0
Core.VECTOR3_RANGE = Core.VECTOR3_MAX - Core.VECTOR3_MIN

Core.VECTOR3_8_QMAX = 2097151
Core.VECTOR3_8_ENCODE_SCALE = Core.VECTOR3_8_QMAX / Core.VECTOR3_RANGE
Core.VECTOR3_8_DECODE_SCALE = Core.VECTOR3_RANGE / Core.VECTOR3_8_QMAX

Core.VECTOR3_12_QMAX = 1073741823
Core.VECTOR3_12_ENCODE_SCALE = Core.VECTOR3_12_QMAX / Core.VECTOR3_RANGE
Core.VECTOR3_12_DECODE_SCALE = Core.VECTOR3_RANGE / Core.VECTOR3_12_QMAX

Core.POS_QMAX = 1048575
Core.POS_ENCODE_SCALE = Core.POS_QMAX / Core.VECTOR3_RANGE
Core.POS_DECODE_SCALE = Core.VECTOR3_RANGE / Core.POS_QMAX

Core.ROT_QMAX = 2047
Core.INV_SQRT2 = 0.7071067811865475
Core.ROT_ENCODE_SCALE = Core.ROT_QMAX / (2.0 * Core.INV_SQRT2)
Core.ROT_DECODE_SCALE = (2.0 * Core.INV_SQRT2) / Core.ROT_QMAX

Core.CFRAME_12_BYTES = 12
Core.CFRAME_20_BYTES = 20

Core.CFRAME_20_ROT_QMAX = 4194303
Core.CFRAME_20_ROT_ENCODE_SCALE = Core.CFRAME_20_ROT_QMAX / (2.0 * Core.INV_SQRT2)
Core.CFRAME_20_ROT_DECODE_SCALE = (2.0 * Core.INV_SQRT2) / Core.CFRAME_20_ROT_QMAX

function Core.resize(writer: Writer, needed_bytes: number)
	const needed_capacity = writer.offset + needed_bytes

	if needed_capacity <= writer.capacity then
		return
	end

	local new_capacity = writer.capacity

	if new_capacity < 1 then
		new_capacity = 1
	end

	while new_capacity < needed_capacity do
		new_capacity *= 2
	end

	const new_buffer = buffer_create(new_capacity)
	buffer_copy(new_buffer, 0, writer.buffer, 0, writer.offset)

	writer.buffer = new_buffer
	writer.capacity = new_capacity
end

function Core. matrix_to_quat(r00: number, r01: number, r02: number, r10: number, r11: number, r12: number, r20: number, r21: number, r22: number): (number, number, number, number)
	const trace = r00 + r11 + r22

	if trace > 0 then
		const s = math.sqrt(trace + 1.0)
		const inv = 0.5 / s

		return (r21 - r12) * inv, (r02 - r20) * inv, (r10 - r01) * inv, 0.5 * s
	elseif r00 > r11 and r00 > r22 then
		const s = math.sqrt(1.0 + r00 - r11 - r22)
		const inv = 0.5 / s

		return 0.5 * s, (r01 + r10) * inv, (r02 + r20) * inv, (r21 - r12) * inv
	elseif r11 > r22 then
		const s = math.sqrt(1.0 + r11 - r00 - r22)
		const inv = 0.5 / s

		return (r01 + r10) * inv, 0.5 * s, (r12 + r21) * inv, (r02 - r20) * inv
	end

	const s = math.sqrt(1.0 + r22 - r00 - r11)
	const inv = 0.5 / s

	return (r02 + r20) * inv, (r12 + r21) * inv, 0.5 * s, (r10 - r01) * inv
end

function Core.quat_to_cframe(px: number, py: number, pz: number, qx: number, qy: number, qz: number, qw: number): CFrame
	const x2 = qx + qx
	const y2 = qy + qy
	const z2 = qz + qz

	const xx = qx * x2
	const xy = qx * y2
	const xz = qx * z2

	const yy = qy * y2
	const yz = qy * z2
	const zz = qz * z2

	const wx = qw * x2
	const wy = qw * y2
	const wz = qw * z2

	return CFrame.new(
		px, py, pz,
		1.0 - (yy + zz), xy - wz, xz + wy,
		xy + wz, 1.0 - (xx + zz), yz - wx,
		xz - wy, yz + wx, 1.0 - (xx + yy)
	)
end

function Core.choose_smallest_three(qx: number, qy: number, qz: number, qw: number): (number, number, number, number)
	const ax = qx < 0 and -qx or qx
	const ay = qy < 0 and -qy or qy
	const az = qz < 0 and -qz or qz
	const aw = qw < 0 and -qw or qw

	local index = 0
	local max_abs = ax

	if ay > max_abs then
		index = 1
		max_abs = ay
	end

	if az > max_abs then
		index = 2
		max_abs = az
	end

	if aw > max_abs then
		index = 3
	end

	const omitted = index == 0 and qx or index == 1 and qy or index == 2 and qz or qw

	if omitted < 0 then
		qx = -qx
		qy = -qy
		qz = -qz
		qw = -qw
	end

	if index == 0 then
		return index, qy, qz, qw
	elseif index == 1 then
		return index, qx, qz, qw
	elseif index == 2 then
		return index, qx, qy, qw
	end

	return index, qx, qy, qz
end

return table.freeze(Core)
