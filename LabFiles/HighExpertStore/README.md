# High Expert Store — IIS + SQL Server 2016

# Aplicação funcional para Windows Server/IIS com .NET 4.6 (.ashx) e SQL Server 2016.
# IIS Web Server
Install-WindowsFeature Web-Server -IncludeManagementTools

# ASP.NET 4.6 e dependências
Install-WindowsFeature Web-Asp-Net45, Web-Net-Ext45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Static-Content

# Cria o App Pool
# PowerShell
& $env:SystemRoot\System32\inetsrv\appcmd.exe add apppool /name:HighExpertStorePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated

# (Opcional) 32-bit em servidor 64 bits:
& $env:SystemRoot\System32\inetsrv\appcmd.exe set apppool "HighExpertStorePool" /enable32BitAppOnWin64:false

# Publica o Website para pasta HighExpertStore

& $env:SystemRoot\System32\inetsrv\appcmd.exe add site /name:"HighExpertStore" /bindings:"http/*:80:" /physicalPath:"C:\inetpub\wwwroot\HighExpertStore"
& $env:SystemRoot\System32\inetsrv\appcmd.exe set app "HighExpertStore/" /applicationPool:"HighExpertStorePool"

# Publicação: ative ASP.NET 4.6 no IIS, crie App Pool v4.0 (Integrated), aponte o site para esta pasta, ajuste a connection string no `web.config` e execute `schema.sql`.
