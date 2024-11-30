#param( [Parameter(Mandatory=$true)] $Jsonfile)
#echo $Jsonfile
param( [Parameter(Mandatory=$true)] $Jsonfile)
#$Json = cat $Jsonfile | ConvertFrom-Json
#echo $Json.users

function CreateADGroup(){
    param( [Parameter(Mandatory=$true)] $groupObject )

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global

}

function RemoveADGroup(){
    param( [Parameter(Mandatory=$true)] $groupObject )

    $name = $groupObject.name
    Remove-ADGroup -Identity $name -Confirm:$false

}


function CreateADUser(){
	param( [Parameter(Mandatory=$true)] $userObject)

    #pull out the name from the Json Object
    $name = $userObject.name
    $password = $userObject.password


    # Generate a "first initial, lastname" structure for username
    $firstname, $lastname = $name.split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    #$SamAccountName = ($name[0] + $name.Split(" ")[1]).ToLower()
    $SamAccountName = $username
    $principalname = $username

    #actually creates the AD user Object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $SamAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    #Add users to the appriorate groups
    foreach($group_name in $userObject.groups){

        try{
            Get-ADGroup -Identity "$group_name"
            Add-ADGroupMember -Identity $group_name -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            write-Warning "User $name Not added to group $group_name because it doesn't exist"
        }
        
    }
}

#Disabling password complixity
function  WeakPasswordPolicy(){
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (GEt-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "Password Complexity = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY 
    rm -force C:\Windows\Tasks\secpol.cfg -confirm: $false
    
}

WeakPasswordPolicy

   
$Json = ( Get-Content $Jsonfile | ConvertFrom-Json)
$Global:Domain = $json.domain

foreach ( $group in $json.groups ){
	CreateADGroup $group
}

foreach ( $user in $json.users ){
	CreateADUser $user
}