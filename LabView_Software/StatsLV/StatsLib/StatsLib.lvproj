<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="13008000">
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="FPGA Counts.vi" Type="VI" URL="../FPGA Counts.vi"/>
		<Item Name="FPGA Pulse.vi" Type="VI" URL="../FPGA Pulse.vi"/>
		<Item Name="FPGA TimeTag.vi" Type="VI" URL="../FPGA TimeTag.vi"/>
		<Item Name="FPGA Toggle.vi" Type="VI" URL="../FPGA Toggle.vi"/>
		<Item Name="USB Close.vi" Type="VI" URL="../USB Close.vi"/>
		<Item Name="USB Open.vi" Type="VI" URL="../USB Open.vi"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Error Cluster From Error Code.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Cluster From Error Code.vi"/>
			</Item>
			<Item Name="Error Converter (ErrCode or Status).vi" Type="VI" URL="../../subvi/Error Converter (ErrCode or Status).vi"/>
			<Item Name="Stats.lvlib" Type="Library" URL="../../x64/Stats.lvlib"/>
			<Item Name="Stats32.dll" Type="Document" URL="../../../Stats/Release/Win32/Stats32.dll"/>
			<Item Name="Stats32.lvlib" Type="Library" URL="../../x86/Stats32.lvlib"/>
		</Item>
		<Item Name="Build Specifications" Type="Build"/>
	</Item>
</Project>
