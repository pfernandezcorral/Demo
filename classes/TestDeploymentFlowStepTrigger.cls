@isTest
public class TestDeploymentFlowStepTrigger {
    @testSetup static void setupData() {
        TestUtilities.getAllMultilicense();
    }
    @testSetup static void setupDataDML() {
        TestUtilities.assignLicense(UserInfo.getUserName(),true, true, true, true, true);
    }
    @isTest static void BranchMgmtEnabled(){
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id,Disable_Validations__c = true);
        insert df;
    }
    static testMethod void testInsertion(){
        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=5);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
   		insert f2;
        
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
        
        Test.startTest();
        try{
        	insert inserts;
            system.assert(true, 'Insert successful.');
        }
        catch(DmlException e){
            system.assert(false, 'Should not have had an exception during insert of flow step.' + e.getMessage());
        }    
        Test.stopTest();
    }
    static testMethod void testUpdate(){
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id, Disable_Validations__c = true);
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
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        insert inserts;
    }
    
    static testMethod void validationsTest () {

        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=5);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f2;
        
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
        
        Deployment_Flow_Step__c df1 = new Deployment_Flow_Step__c(
                Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[2].Id);
        Deployment_Flow_Step__c df2 = new Deployment_Flow_Step__c(
                Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id);

        insert df1;
        insert df2;
        
        Test.startTest();

        df1.Branch__c = '';
        try{
            update df1;
            update df2;
            system.assert(false, 'Should have failed due to missing branch name.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.ALL_FLOW_STEPS_WITH_BRANCH_NAME)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        } 

        df1.Branch__c = 'dev1';
        df1.Source_Environment__c = null;
        try{
            update df1;
            update df2;
            system.assert(false, 'Should have failed due to missing Environment.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.MUST_HAVE_SOURCE_AND_DESTINATION)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }  

        df1.Branch__c = 'dev2';
        df1.Source_Environment__c = Le[0].Id;
        try{
            update df1;
            update df2;
            system.assert(false, 'Should have failed due to repeated branch name.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.REPEATED_BRANCH_NAME)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        }  
        
        df1.Branch__c = 'dev1';
        df1.Source_Environment__c = Le[1].Id;
        try{
            update df1;
            update df2;
            system.assert(false, 'Should have failed due to repeated source Environment.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.REPEATED_SOURCE_ENVIRONMENT)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        
        df1.Branch__c = 'Env0';
        df1.Source_Environment__c = Le[0].Id;
        df2.Branch__c = 'Env1';
        update df1;
        update df2;
        df.Equal_Branch_Environment_Name__c = true;
        update df;
        df1.Branch__c = 'dev1';
        df1.Source_Environment__c = Le[0].Id;
        try{
            update df1;
            update df2;
            system.assert(false, 'Should have failed due to a mismatch between Environment and Branch names.');
        }
        catch(DmlException e){
            Boolean expectedExceptionThrown = e.getMessage().contains(Label.BRANCH_AND_SOURCE_ENVIRONMENT_EQUALS)?true:false;
            system.debug('Actual Message thrown 1: '+e.getMessage());
            System.AssertEquals(expectedExceptionThrown, true);
        } 

        Test.stopTest();
    } 
}