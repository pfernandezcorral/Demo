@isTest
public class TestPermissionSetExplorerExt {

	@testSetup 
    static void setupData() {
		createPermissionSets();
        insertUser();
	}
	
	static testMethod void TestExplorer() {

		Persona__c releaseManager= createPersona('Test Release Manager');
        List<Persona_Permission__c> releaseManagerPermissions=createPersonaPermissions(releaseManager.Id, 'UnitTest_A_CopadoTest,UnitTest_B_CopadoTest,UnitTest_C_CopadoTest');
        
        User_Persona_Assignment__c ppa=new User_Persona_Assignment__c(Persona__c=releaseManager.Id, User__c=getTestUser().Id, Status__c='Draft');
        insert ppa;

		Test.startTest();
        PermissionSetExplorerExt pse=new PermissionSetExplorerExt();
        PermissionSetExplorerExt.PersonaId=releaseManager.Id;
        List<SelectOption> personas=pse.getPersonas();
		PermissionSetExplorerExt.LoadPermissions();
		Test.stopTest();
	}

	private static User getTestUser(){
        return [select Id from User where username ='futureuser777@test-copado.org'];
    }
    @Future
    public static void insertUser() {
        Profile p=[SELECT Id FROM Profile WHERE Name='System Administrator'];
        //removed chatter dependency
        User futureUser=new User(firstname='Future', lastname='User',
            alias='future', 
            email='test@test.org',
            emailencodingkey='UTF-8', 
			languagelocalekey='en_US', 
            localesidkey='en_US', 
			profileid=p.Id, 
            timezonesidkey='America/Los_Angeles',
            username='futureuser777@test-copado.org'
            );
        insert(futureUser);
    }
    
    @Future
    private static void createPermissionSets(){
        List<PermissionSet> perms=new List<PermissionSet>();
        perms.add(new PermissionSet(Name='UnitTest_A_CopadoTest', Label='UnitTest_A_CopadoTest'));
        perms.add(new PermissionSet(Name='UnitTest_B_CopadoTest', Label='UnitTest_B_CopadoTest'));
        perms.add(new PermissionSet(Name='UnitTest_C_CopadoTest', Label='UnitTest_C_CopadoTest'));
        System.debug('inserting Permission sets: ' + perms);
        insert perms;

        List<FieldPermissions> Lfp=new List<FieldPermissions>();
        Lfp.add(new FieldPermissions(Field='Account.Rating',ParentId=perms[0].Id,PermissionsEdit=false,PermissionsRead=true,SobjectType='Account'));
		Lfp.add(new FieldPermissions(Field='Account.Rating',ParentId=perms[1].Id,PermissionsEdit=true,PermissionsRead=true,SobjectType='Account'));
		insert Lfp;

		List<ObjectPermissions> Lop=new List<ObjectPermissions>();
		Lop.add(new ObjectPermissions(ParentId=perms[0].Id,PermissionsCreate=false,PermissionsDelete=false,PermissionsEdit=false,PermissionsModifyAllRecords=false,PermissionsRead=true,PermissionsViewAllRecords=false,SobjectType='Account'));
		Lop.add(new ObjectPermissions(ParentId=perms[1].Id,PermissionsCreate=true,PermissionsDelete=false,PermissionsEdit=true,PermissionsModifyAllRecords=false,PermissionsRead=true,PermissionsViewAllRecords=false,SobjectType='Account'));
		insert Lop;
	}
    private static Persona__c createPersona(String n){
        Persona__c x=new Persona__c(Name=n);
        insert x;
        return x;
    }
    private static List<Persona_Permission__c> createPersonaPermissions(Id personaId, String perms){
        List<Persona_Permission__c> pps=new List<Persona_Permission__c>();
        for(String s : perms.split(',')){
            pps.add(new Persona_Permission__c(Persona__c=personaId, Permission_Set_Name__c=s));
        }
        insert pps;
        return pps;
    }
}