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

   
$Json = ( Get-Content $Jsonfile | ConvertFrom-Json)
$Global:Domain = $json.domain

foreach ( $group in $json.groups ){
	CreateADGroup $group
}

foreach ( $user in $json.users ){
	CreateADUser $user
}