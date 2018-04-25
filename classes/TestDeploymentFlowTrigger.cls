@isTest
public class TestDeploymentFlowTrigger {
    @testSetup static void setupTestData(){
        TestUtilities.enableLicenses(1,1,1,1,1,2);
    }
    @testSetup static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }
    public class MyTestClassException extends Exception {}
    static testMethod void featureNotEnabled(){
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=false);
        try {
            insert df;    
            system.assert(df.Id != null);
        } catch(Exception e) {
            system.assert(false, 'Exception thrown: '+e.getMessage());
        }
    }
    static testMethod void featureLimitExceeded_inserts(){
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id);
        insert df;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;
        
        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        try{
        	insert inserts;
            system.assert(true, 'No expections thrown (expected)');
        }
        catch(Exception e){
            system.assert(false, 'Exception thrown 1: '+e.getMessage());
        }
		  
        // Insert an inactive flow which should not trigger the exception.
        try {
            df = new Deployment_Flow__c(Name='test', Active__c=false);
        	insert df;
            system.assert(true, 'No expections thrown (expected)');
        }
        catch(Exception e){
            system.debug('Actual Message thrown 2: '+e.getMessage());
            System.assert(false, '');
        }
        test.startTest();
        // Insert an active flow (we are now over the limit), so an exception must be triggered.
        try{
            df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id);
        	insert df;
            Deployment_Flow_Step__c dfs = new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id);
            insert dfs;

            system.assert(false, 'Should not have reached this code.');
        }
        catch(Exception e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_LICENSE_EXCEEDED)?true:false;
            system.debug('Actual Message thrown 3: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }
        test.stopTest();
    }
    static testMethod void featureLimitExceeded_update(){
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=false, Main_Branch__c='master', Git_Repository__c=gr.Id);
        insert df;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;
        
        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev3', Source_Environment__c=Le[2].Id, Destination_Environment__c=Le[3].Id));
        insert inserts;

        test.startTest();
        // Update an inactive flow (we are now over the limit), so an exception must be triggered.
        try {
            df.Active__c = true;
        	update df;
			system.assert(false, 'Should not have reached this code.');
        }
        catch (DmlException e) {
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_MGMT_LICENSE_EXCEEDED)?true:false;
            system.debug('Actual Message thrown 5: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }
        test.stopTest();
    }
}