<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="12008004">
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
		<Item Name="Counts.vi" Type="VI" URL="../Counts.vi"/>
		<Item Name="TimeTag.vi" Type="VI" URL="../TimeTag.vi"/>
		<Item Name="TTLPulse.vi" Type="VI" URL="../TTLPulse.vi"/>
		<Item Name="TTLToggle.vi" Type="VI" URL="../TTLToggle.vi"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Error Cluster From Error Code.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Cluster From Error Code.vi"/>
				<Item Name="Space Constant.vi" Type="VI" URL="/&lt;vilib&gt;/dlg_ctls.llb/Space Constant.vi"/>
			</Item>
			<Item Name="Error Converter (ErrCode or Status).vi" Type="VI" URL="../subvi/Error Converter (ErrCode or Status).vi"/>
			<Item Name="FPGA Counts.vi" Type="VI" URL="../StatsLib/FPGA Counts.vi"/>
			<Item Name="FPGA Pulse.vi" Type="VI" URL="../StatsLib/FPGA Pulse.vi"/>
			<Item Name="FPGA TimeTag.vi" Type="VI" URL="../StatsLib/FPGA TimeTag.vi"/>
			<Item Name="FPGA Toggle.vi" Type="VI" URL="../StatsLib/FPGA Toggle.vi"/>
			<Item Name="Stats.lvlib" Type="Library" URL="../x64/Stats.lvlib"/>
			<Item Name="Stats32.dll" Type="Document" URL="../../Stats/Release/Win32/Stats32.dll"/>
			<Item Name="Stats32.lvlib" Type="Library" URL="../x86/Stats32.lvlib"/>
			<Item Name="USB Close.vi" Type="VI" URL="../StatsLib/USB Close.vi"/>
			<Item Name="USB Open.vi" Type="VI" URL="../StatsLib/USB Open.vi"/>
		</Item>
		<Item Name="Build Specifications" Type="Build"/>
	</Item>
</Project>
