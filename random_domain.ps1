param( [Parameter(Mandatory=$true)] $OutputJsonfile)

$group_names = [System.Collections.ArrayList](Get-Content "code/group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "code/first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "code/last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "code/passwords.txt")

#$group_names = (Get-Content "code/group_names.txt")

$groups = @()
$users = @()

$num_groups = 10
for ( $i = 0; $i -lt $num_groups; $i++ ){
    $group_name = (Get-Random -InputObject $group_names)
    $group = @{ "name" = "$group_name" }
    $groups += $group
    $group_names.Remove($group_name)
}

$num_users = 100
for ( $i = 0; $i -lt $num_users; $i++ ){
    $first_name = (Get-Random -InputObject $first_names)
    $last_name = (Get-Random -InputObject $last_names)
    $password = (Get-Random -InputObject $passwords)
    
    $new_user = @{
        "name"="$first_name $last_name"
        "password"="$password"
        "groups" = @( (Get-Random -InputObject $groups).name )
        }
    #echo $new_user
    $users += $new_user

    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
}
#hashtable of the domain

ConvertTo-Json -InputObject @{
    "domain"= "xyz.corp"
    "groups"=$groups
    "users"=$users
} | Out-File $OutputJsonfile

#echo $groups
#echo (Get-Random -InputObject $group_names)