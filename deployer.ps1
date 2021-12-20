# Funcao responsavel por ler os dados do ini
function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        } 
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

try {
  
  # Diretorio Base
  $BaseDir = "D:\totvs\protheus\treinamento\Protheus12"
  
  # Diretorio com as includes
  $IncludeFolder = "$BaseDir\include"
  
  # Caminho do RPO onde os fontes eram compilados
  $BuildPath = "$BaseDir\apo\devops"
  
  # Caminho do novo RPO
  $DestPath = "$BaseDir\apo\2EASYAPP\$ENV:CI_COMMIT_SHORT_SHA"
  
  # Caminho do appserver de producao
  $ProductionAppServer = "$BaseDir\bin\appserver_2easyapp"

  echo "$ProductionAppServer\appserver.ini"
  
  # Le o arquivo ini e busca o SourcePath atual
  $IniData = Get-IniContent "$ProductionAppServer\appserver.ini"
  $SourcePath = $IniData['2EASYAPP']['SourcePath']
  Write-Host "RPO Current Folder: $SourcePath"
  
  # Copia o RPO atual para o diretorio BUILD
  Write-Host "Copying file $SourcePath\tttp120.rpo to $BuildPath"
  Copy-Item -Path $SourcePath\* -Destination $BuildPath -Recurse -Force
  
  # Compila os fontes utilizando o appserver
  cd $BaseDir\bin\appserver_devops
  
  ./appserver.exe -compile -files="$ENV:CI_PROJECT_DIR" -includes="$IncludeFolder" -env=BUILD
  ./appserver.exe -compile -genpatch -files="$ENV:CI_PROJECT_DIR" -includes="$IncludeFolder" -env=BUILD -patchtype=ptm
  
  # Criando estrutura do novo RPO e copia o mesmo para o novo diretorio
  New-Item -ItemType Directory -Path $DestPath
  Copy-Item -Path $BuildPath\* -Destination "$DestPath\tttp120.rpo" -Recurse -Force
  
  # Troca a informacao no INI de producao
  Copy-Item -Path "$ProductionAppServer\appserver.ini" -Destination "$ProductionAppServer\appserver_Bkp.ini" -Force
  
  Write-Host "Updating appserver.ini..."
  Write-Host "Previous content: $SourcePath" 
  Write-Host "New content: $DestPath" 
  
  (Get-Content $ProductionAppServer\appserver.ini).replace($SourcePath, $DestPath) | Set-Content $ProductionAppServer\appserver.ini

}
catch
{
    write-host "Caught an exception"
    exit 1
}