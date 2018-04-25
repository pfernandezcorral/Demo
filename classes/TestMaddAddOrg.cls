@isTest
private class TestMaddAddOrg {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testAdd_Success(){
        Org__c masterOrg = testMethodUtilities.create('OrgNameM','Production','PASSWORDM','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        Org__c testOrg1 = testMethodUtilities.create('OrgName1','Production','PASSWORD1','SFDC_OrgId1','SFDC_TOKEN','USERNAME1', System.now());
        Org__c testOrg2 = testMethodUtilities.create('OrgName2','Production','PASSWORD2','SFDC_OrgId2','SFDC_TOKEN','USERNAME2', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        orgs.add(testOrg1);
        orgs.add(testOrg2);
        insert orgs;
        
        Deployment__c oldDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert oldDeployment;
        Destination_Org__c testDestOrg1 = testMethodUtilities.create(oldDeployment.Id,'Draft',testOrg1.Id);
        Destination_Org__c testDestOrg2 = testMethodUtilities.create(oldDeployment.Id,'Draft',testOrg2.Id);
        insert testDestOrg1;
        insert testDestOrg2;
        
        Deployment__c newDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        ext.orgs = orgs;
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.add();
        system.assertEquals(new PageReference('/'+newDeployment.Id).getUrl(), result.getUrl());
        system.assertEquals(2,[select Id from Destination_Org__c where Deployment__c=:newDeployment.Id].size());
        Test.stopTest();
    }
    static testMethod void test_Cancel(){
        Org__c masterOrg = testMethodUtilities.create('OrgNameM','Production','PASSWORDM','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        Org__c testOrg1 = testMethodUtilities.create('OrgName1','Production','PASSWORD1','SFDC_OrgId1','SFDC_TOKEN','USERNAME1', System.now());
        Org__c testOrg2 = testMethodUtilities.create('OrgName2','Production','PASSWORD2','SFDC_OrgId2','SFDC_TOKEN','USERNAME2', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        orgs.add(testOrg1);
        orgs.add(testOrg2);
        insert orgs;
        
        Deployment__c oldDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert oldDeployment;
        Destination_Org__c testDestOrg1 = testMethodUtilities.create(oldDeployment.Id,'Draft',testOrg1.Id);
        Destination_Org__c testDestOrg2 = testMethodUtilities.create(oldDeployment.Id,'Draft',testOrg2.Id);
        insert testDestOrg1;
        insert testDestOrg2;
        
        Deployment__c newDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testOrg1.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        ext.orgs  =orgs;
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.cancel();
        ID resultID = testOrg1.Id;
        Test.stopTest();
        system.assert(result != null);
    }
    static testMethod void test_Add_Error(){
        Org__c masterOrg = testMethodUtilities.create('OrgNameM','Production','PASSWORDM','SFDC_OrgIdM','SFDC_TOKEN','USERNAMEM', System.now());
        List<Org__c> orgs = new List<Org__c>();
        insert masterOrg;
        
        Deployment__c oldDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),masterOrg.Id,'Deploy now','Pending');
        insert oldDeployment;
        
        Deployment__c newDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),masterOrg.Id,'Deploy now','Pending');
        insert newDeployment;
        
        PageReference pref = Page.MassAddDestOrgs;
        pref.getParameters().put('id',masterOrg.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(orgs);
        MassAddDestOrgs ext = new MassAddDestOrgs(con);
        
        Test.startTest();
        ext.dummy.Deployment__c = newDeployment.Id;
        PageReference result = ext.add();
        system.assertEquals(null, result);
        system.assert(testMethodUtilities.hasMessage(Label.SELECT_AT_LEAST_ONE_RECORD));
        Test.stopTest();
    }
}