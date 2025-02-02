function Get-VerkadaAccessUser
{
	<#
		.SYNOPSIS
		Gets an Access User in an organization by userId
		
		.DESCRIPTION
		This function is used to get all the details about an indivual Access user in an org.
		This function is used to rename a camera or cameras in a Verkada org.
		The org_id and reqired tokens can be directly submitted as parameters, but is much easier to use Connect-Verkada to cache this information ahead of time and for subsequent commands.
		
		.LINK
		https://github.com/bepsoccer/verkadaModule/blob/master/docs/function-documentation/Get-VerkadaAccessUser.md

		.EXAMPLE
		Get-VerkadaAccessUser -userId 'aefrfefb-3429-39ec-b042-userAC'
		This will retrieve the user with userId aefrfefb-3429-39ec-b042-userAC.  The org_id and tokens will be populated from the cached created by Connect-Verkada.
		
		.EXAMPLE
		Get-VerkadaAccessUser -userId 'aefrfefb-3429-39ec-b042-userAC' -org_id '7cd47706-f51b-4419-8675-3b9f0ce7c12d' -x_verkada_token 'a366ef47-2c20-4d35-a90a-10fd2aee113a' -x_verkada_auth 'auth-token-uuid-dscsdc' -usr 'a099bfe6-34ff-4976-9d53-ac68342d2b60'
		This will retrieve the user with userId aefrfefb-3429-39ec-b042-userAC.  The org_id and tokens are submitted as parameters in the call.
	#>

	[CmdletBinding(PositionalBinding = $true)]
	Param(
		#The UUID of the organization the user belongs to
		[Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$')]
		[String]$org_id = $Global:verkadaConnection.org_id,
		#The UUID of the user
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$')]
		[String]$userId,
		#The Verkada(CSRF) token of the user running the command
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$')]
		[string]$x_verkada_token = $Global:verkadaConnection.csrfToken,
		#The Verkada Auth(session auth) token of the user running the command
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$x_verkada_auth = $Global:verkadaConnection.userToken,
		#The UUID of the user account making the request
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$')]
		[string]$usr = $Global:verkadaConnection.usr
	)

	Begin {
		#parameter validation
		if ([string]::IsNullOrEmpty($org_id)) {throw "org_id is missing but is required!"}
		if ([string]::IsNullOrEmpty($x_verkada_token)) {throw "x_verkada_token is missing but is required!"}
		if ([string]::IsNullOrEmpty($x_verkada_auth)) {throw "x_verkada_auth is missing but is required!"}
		if ([string]::IsNullOrEmpty($usr)) {throw "usr_id is missing but is required!"}
		
		$url = "https://vgateway.command.verkada.com/graphql"

		$queryBase = 'query GetAccessUserProfile($id: ID) {
	user(id: $id) {
		...AccessUserProfile
		__typename
	}
}'

		$AccessUserProfileFragment = 'fragment AccessUserProfile on User {
	...AccessUser
	accessCardsRaw {
		cacheId
		organizationId
		userId
		active
		cardId
		cardType
		lastUsed
		modified
		cardParams {
			cardNumber
			cardNumberHex
			facilityCode
			__typename
		}
		__typename
	}
	userCodesRaw {
		code
		lastUsed
		__typename
	}
	__typename
}'

		$AccessUserFragment = 'fragment AccessUser on User {
	...AccessUserBasic
	employeeId
	employeeTitle
	department
	departmentId
	companyName
	employeeType
	mobileAccess
	bluetoothAccess
	accessUserRoles {
		role
		__typename
	}
	accessGroups {
		group {
			userGroupId
			name
			__typename
		}
		added
		__typename
	}
	accessCards {
		active
		cardId
		cardType
		lastUsed
		modified
		cardParams {
			cardNumber
			facilityCode
			__typename
		}
		__typename
	}
	userCodes {
		code
		lastUsed
		__typename
	}
	roleGrant: roleGrants(filter: {includeExpired: true}) {
		granteeId
		grantId
		entityId
		realGranteeId
		start
		expiration
		role {
			key
			name
			roleId
			permissions {
				permission
				permissionId
				__typename
			}
			__typename
		}
		__typename
	}
	__typename
}'

		$AccessUserBasicFragment = 'fragment AccessUserBasic on User {
	userId
	name
	phone
	firstName
	middleName
	lastName
	email
	emailVerified
	organizationId
	created
	modified
	provisioned
	lastLogin
	lastActiveAccess
	deactivated
	deleted
	roleGrant: roleGrants(filter: {includeExpired: true}) {
		granteeId
		grantId
		entityId
		organizationId
		realGranteeId
		roleId
		start
		expiration
		__typename
	}
	__typename
}'

		$query = $queryBase + "`n" + $AccessUserProfileFragment + "`n" + $AccessUserFragment + "`n" + $AccessUserBasicFragment
	} #end begin
	
	Process {
		$variables = '{"id":""}' | ConvertFrom-Json
		$variables.id = $userId

		$user = Invoke-VerkadaGraphqlCall $url -query $query -qlVariables $variables -org_id $org_id -method 'Post' -propertyName 'user' -x_verkada_token $x_verkada_token -x_verkada_auth $x_verkada_auth -usr $usr
		return $user
	} #end process
} #end function