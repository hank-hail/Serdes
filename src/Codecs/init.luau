--!strict
--!native
const Core = require(script.Core)

export type Writer = Core.Writer
export type Reader = Core.Reader
export type Codec<T> = Core.Codec<T>

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
	CFrame_17: Codec<CFrame>,

	[string]: Codec<any>,
}

const Codecs = {} :: Codecs

for name, codec in script:GetChildren() do
	if not codec:IsA'ModuleScript' or codec.Name == 'Core' then 
		continue 
	end
	
	Codecs[codec.Name] = require(codec) :: Codec<any>
end

return table.freeze(Codecs) :: Codecs
