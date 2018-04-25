@isTest
private class TestPromotionTriggerHandler {
    private class ApplicationException extends Exception {}
    @testSetup static void setupData() {
        TestUtilities.getAllMultilicense();
    }
    @testSetup
    static void setupDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.insertUser('user1-TestPromotionTriggerHandler@test-copado.org','System Administrator');
        TestUtilities.assignLicense('user1-TestPromotionTriggerHandler@test-copado.org', false, true, false);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, true);
    }
    static testMethod void deletePromotion(){
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, null);
        testPromotion.Destination_Environment__c = null;
        insert testPromotion;
        
        delete testPromotion;
        system.assertEquals(0, [select Id from Promotion__c where Id=:testPromotion.Id].size());
        undelete testPromotion;
        system.assertEquals(1, [select Id from Promotion__c where Id=:testPromotion.Id].size());
    }
    static testMethod void testSettingOfFlow_insert(){    
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        insert testProject;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;
        
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        update testProject;

        test.startTest();
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        testPromotion.Destination_Environment__c = null;
        insert testPromotion;
        test.stopTest();

        Promotion__c result = [select Id, Source_Environment__c, Destination_Environment__c from Promotion__c where Id=:testPromotion.Id limit 1];
        system.assertEquals(env2.Id, result.Destination_Environment__c);
    }
    static testMethod void testSettingOfFlow_update(){    
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        insert testProject;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Production Environment', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        update testProject;

        Promotion__c testPromotion = new Promotion__c();
        testPromotion.Project__c = testProject.Id;
        testPromotion.Source_Environment__c = env1.Id;
        testPromotion.Send_Deployment_Complete_email__c = false;
        insert testPromotion;

        Promotion__c result = [select Id, Source_Environment__c, Destination_Environment__c from Promotion__c where Id=:testPromotion.Id limit 1];
        test.startTest();
        system.assertEquals(env2.Id, result.Destination_Environment__c );
        testPromotion.Destination_Environment__c = null;
        update testPromotion;
        test.stopTest();

        
        result = [select Id, Source_Environment__c, Destination_Environment__c from Promotion__c where Id=:testPromotion.Id limit 1];
        system.assertEquals(env2.Id, result.Destination_Environment__c );
    }
    static testMethod void triggerTest() {        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c env1 = new Environment__c(Name='UAT Environment', Type__c='Production');
        Environment__c env2 = new Environment__c(Name='Production Environment', Type__c='Production');
        insert envList;


        List<Org__c> orgList = new List<Org__c>();
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        orgList.add(testOrg1);
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        orgList.add(testOrg2);
        insert orgList;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        
        Set<Id> promotionIds = new Set<Id>();
        List<Promotion__c> promotions = new List<Promotion__c>();
        for(Integer i=0; i<10; i++){
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            promotions.add(testPromotion);
        }
        insert promotions;
        system.debug('########################## PROMOTIONS == '+promotions.size());
        
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Promotion__c p : promotions){
            promotionIds.add(p.Id);
            for(Integer i=0; i<5; i++){
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Environment__c = env1.Id;
                testUserStory.Project__c = testProject.Id;
                testUserStory.Promote_Change__c = true;
                testUserStory.Promote_and_Deploy__c = true;
                userStories.add(testUserStory);
            }
        }
        insert userStories;
        Test.startTest();
        system.debug('########################## USER STORIES == '+userStories.size());
        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        Integer counter = 0;
        for(User_Story__c u : userStories){
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = u.Id;
            pus.Promotion__c = promotions[counter].Id;
            promotedStories.add(pus);
            counter++;
            if(counter==(promotions.size()-1))counter=0;
        }
        insert promotedStories;
        
        system.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
        
        //test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
        //updated to Completed. Then, the User Stories will be updated as well.
        List<Deployment__c> deploys = new List<Deployment__c>();
        for(Promotion__c p : promotions){
            //p.Status__c = 'Completed';
            deploys.add(new Deployment__c(name='test',promotion__c=p.id));
        }
        insert deploys;
        for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
        update deploys;
        

        update promotions;
        Test.stopTest();
        
        List<Promoted_User_Story__c> results = [select Id, User_Story__c, Promotion__c, User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                            from Promoted_User_Story__c
                                            where Promotion__c IN :promotionIds];
        for(Promoted_User_Story__c pus : results){
            system.assertEquals(false, pus.User_Story__r.Promote_Change__c);
            system.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);
            system.assertEquals(env2.Id, pus.User_Story__r.Environment__c);
        }
    }
    static testMethod void triggerTestValidations() {
        Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
        insert feature;
        
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'g');
		insert gitRepo;
        Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
        insert flow;
        Deployment_Flow__c CBMflow = CMTestMethodUtilities.createCBMFlow('flow', true, gitRepo.Id, 'master');
        insert CBMFlow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        
        Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert env2;
        Environment__c env3 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert env3;
        Environment__c env4 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert env4;
        
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flow.Id);
        dfs2.Branch__c = 'branch2';
        insert dfs2;
        Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, CBMFlow.Id);
        dfs4.Branch__c = 'branch4';
        insert dfs4;

        Test.startTest();
        Promotion__c promotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        try {
        	insert promotion;
            System.assert(false, 'This must fail');
        } catch (Exception e) {
            System.assert(true, e.getMessage().contains(Label.PROMOTION_FLOW_INACTIVE));                  
        }
        flow.Active__c = true;
        update flow;
                   
        // Run test as a CCM User
        User user = [SELECT Id FROM User WHERE username ='user1-TestPromotionTriggerHandler@test-copado.org'];
        System.runAs(user) {
            
            Project__c testProject2 = CMTestMethodUtilities.createProject('test project 2');
        	testProject2.Deployment_Flow__c = flow.Id;
        	insert testProject2;
                
            Org__c testOrg3 = CMTestMethodUtilities.createOrg('MyOrg3', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), env3.Id);
            insert testOrg3;
            Org__c testOrg4 = CMTestMethodUtilities.createOrg('MyOrg4', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), env4.Id);
            insert testOrg4;
                        
            Promotion__c promotion2 = CMTestMethodUtilities.createPromotion(testProject2.Id, env3.Id);
            
            // Invalid destination Org since it's not a Sandbox
            try {
                insert promotion2;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(Label.CCM_DESTINATION_ORG_INVALID));                  
            }
            System.assert(true, env4.Type__c.contains('Production'));
            env4.Type__c = 'Sandbox';
            update env4;
            testOrg4.Org_Type__c = 'Sandbox';
            update testOrg4;
            System.assertEquals('Sandbox', env4.Type__c);
            
            // Invalid CBM Flow since there is no Git Repository nor Main Branch
            try {
                insert promotion2;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(Label.CBM_FLOW_INVALID));                  
            }
            testProject2.Deployment_Flow__c = CBMFlow.Id;
            update testProject2;
    
            // Valid CBM Promotion
            insert promotion2;
            System.assertEquals(true, promotion2.Id != null); 
            
            User_Story__c us = CMTestMethodUtilities.createUserStory('test');
            us.Environment__c = env3.Id;
            us.Org_Credential__c = testOrg3.Id;
            us.Project__c = testProject2.Id;
            us.Promote_Change__c = true;
            us.Promote_and_Deploy__c = true;
            insert us;
    
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = us.Id;
            pus.Promotion__c = promotion2.Id;
            insert pus;
    
            //test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
            //updated to Completed. Then, the User Stories will be updated as well.
            Deployment__c deployment = new Deployment__c(name = 'test', promotion__c = promotion2.id);
            insert deployment;
            system.assertEquals(true, deployment.Id != null);
            deployment.Status__c='Completed Successfully';
            update deployment;
            
            pus = [SELECT User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                            FROM Promoted_User_Story__c
                                            WHERE Id = :pus.Id];
            System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
            System.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);         
            system.assertEquals(env4.Id, pus.User_Story__r.Environment__c);            
        }
        Test.stopTest();
    }
    static testMethod void triggerTestValidationsWithRelease() {
        Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=6);
        insert feature;
        Feature__c feature2 = new Feature__c(Name='Git Backup', Enabled__c=true);
   		insert feature2;
        
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'g');
		insert gitRepo;
        Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
        insert flow;
        Deployment_Flow__c CBMflow = CMTestMethodUtilities.createCBMFlow('flow', false, gitRepo.Id, 'master');
        insert CBMFlow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        
        Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert env2;
        Environment__c env3 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
       	insert env3;
        Environment__c env4 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert env4;
        
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, flow.Id);
        insert dfs2;
        Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env3.Id, env4.Id, CBMFlow.Id);
        dfs4.Branch__c = 'branch4';
        insert dfs4;
        
        CBMFlow.Active__c = true;
        update CBMFlow;
        
        Release__c testRelease = CMTestMethodUtilities.createRelease('test');
       	testRelease.Project__c = testProject.Id;
        insert testRelease;
        
        Promotion__c promotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
        promotion.Release__c = testRelease.Id;
        try {
        	insert promotion;
            System.assert(false, 'This must fail');
        } catch (Exception e) {
            System.assert(true, e.getMessage().contains(Label.PROMOTION_FLOW_INACTIVE));                  
        }
        flow.Active__c = true;
        update flow;
                   
        // Run test as a CCM User
        User user = [SELECT Id FROM User WHERE username ='user1-TestPromotionTriggerHandler@test-copado.org'];
        System.runAs(user) {
            
            Project__c testProject2 = CMTestMethodUtilities.createProject('test project 2');
        	testProject2.Deployment_Flow__c = flow.Id;
        	insert testProject2;
                
            Org__c testOrg3 = CMTestMethodUtilities.createOrg('MyOrg3', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), env3.Id);
            insert testOrg3;
            Org__c testOrg4 = CMTestMethodUtilities.createOrg('MyOrg4', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), env4.Id);
            insert testOrg4;
                        
            Release__c testRelease2 = CMTestMethodUtilities.createRelease('test Release');
        	testRelease2.Project__c = testProject2.Id;
        	insert testRelease2;
            
            Promotion__c promotion2 = CMTestMethodUtilities.createPromotion(null, env3.Id);
            promotion2.Release__c = testRelease2.Id;

            Test.startTest();
            // Invalid destination Org since it's not a Sandbox
            try {
                insert promotion2;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(Label.CCM_DESTINATION_ORG_INVALID));                  
            }
            System.assert(true, env4.Type__c.contains('Production'));
            env4.Type__c = 'Sandbox';
            update env4;
            testOrg4.Org_Type__c = 'Sandbox';
            update testOrg4;
            System.assertEquals('Sandbox', env4.Type__c);
            
            // Invalid CBM Flow since there is no Git Repository nor Main Branch
            try {
                insert promotion2;
                System.assert(false, 'This must fail');
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(Label.CBM_FLOW_INVALID));                  
            }
            testProject2.Deployment_Flow__c = CBMFlow.Id;
            update testProject2;
    
            // Valid CBM Promotion
            insert promotion2;
            System.assertEquals(true, promotion2.Id != null); 
            
            User_Story__c us = CMTestMethodUtilities.createUserStory('test');
            us.Environment__c = env3.Id;
            us.Org_Credential__c = testOrg3.Id;
            us.Project__c = testProject2.Id;
            us.Promote_Change__c = true;
            us.Promote_and_Deploy__c = true;
            insert us;
    
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = us.Id;
            pus.Promotion__c = promotion2.Id;
            insert pus;
    
            //test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
            //updated to Completed. Then, the User Stories will be updated as well.
            Deployment__c deployment = new Deployment__c(name = 'test', promotion__c = promotion2.id);
            insert deployment;
            system.assertEquals(true, deployment.Id != null);
            deployment.Status__c='Completed Successfully';
            update deployment;
            
            pus = [SELECT User_Story__r.Promote_Change__c, User_Story__r.Promote_and_Deploy__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                            FROM Promoted_User_Story__c
                                            WHERE Id = :pus.Id];
            System.assertEquals(false, pus.User_Story__r.Promote_Change__c);
            System.assertEquals(false, pus.User_Story__r.Promote_and_Deploy__c);         
            system.assertEquals(env4.Id, pus.User_Story__r.Environment__c);
            Test.stopTest();
        }            
    }
    static testMethod void testSetSourceOrgFromEnvironment(){
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        insert testProject;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
        insert env1;
        Org__c testOrg = CMTestMethodUtilities.createOrg('OrgName','Production','','SFDC_OrgId','','USERNAME', System.now(), env1.Id);
        insert testOrg;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
        insert env2;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('OrgName2','Sandbox','','SFDC_OrgId2','','USERNAME2', System.now(), env2.Id);
        insert testOrg2;
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        update testProject;
        
        test.startTest();
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        insert testPromotion;
        test.stopTest();
        
        Promotion__c result = [select Id, Source_Environment__c, Source_Org_Credential__c from Promotion__c where Id=:testPromotion.Id limit 1];
        system.assertEquals(testOrg.Id, result.Source_Org_Credential__c);
    }
    
    static testMethod void testSetDefaultEnvironment(){
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        insert testProject;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
        insert env1;
        Org__c testOrg = CMTestMethodUtilities.createOrg('OrgName2','Production','','SFDC_OrgId2','','USERNAME2', System.now(), env1.Id);
        insert testOrg;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('OrgName3','Production','','SFDC_OrgId3','','USERNAME3', System.now(), env1.Id);
        testOrg2.Default_Credential__c = true;
        insert testOrg2;
        
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId4');
        insert env2;
        Org__c testOrg4 = CMTestMethodUtilities.createOrg('OrgName4','Sandbox','','SFDC_OrgId4','','USERNAME4', System.now(), env2.Id);
        testOrg4.Default_Credential__c = true;
        insert testOrg4;
        Org__c testOrg5 = CMTestMethodUtilities.createOrg('OrgName5','Sandbox','','SFDC_OrgId5','','USERNAME5', System.now(), env2.Id);
        insert testOrg5;
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        update testProject;
        
        test.startTest();
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        insert testPromotion;
        test.stopTest();
        
        Promotion__c result = [select Id, Source_Org_Credential__c, Destination_Org_Credential__c from Promotion__c where Id=:testPromotion.Id limit 1];
        system.assertEquals(testOrg2.Id, result.Source_Org_Credential__c);
        system.assertEquals(testOrg4.Id, result.Destination_Org_Credential__c);
    }
    
    static testMethod void triggerTestwithRelease() {
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c env1 = new Environment__c(Name='UAT Environment');
        envList.add(env1);
        Environment__c env2 = new Environment__c(Name='Production Environment');
        envList.add(env2);
        insert envList;

        Release__c testRelease = CMTestMethodUtilities.createRelease('test Release');
        testRelease.Project__c = testProject.Id;
        insert testRelease;

        List<Org__c> orgList = new List<Org__c>();
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        orgList.add(testOrg1);
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        orgList.add(testOrg2);
        insert orgList;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        
        Set<Id> promotionIds = new Set<Id>();
        List<Promotion__c> promotions = new List<Promotion__c>();
        for(Integer i=0; i<5; i++){
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            testPromotion.Release__c = testRelease.Id;
            promotions.add(testPromotion);
        }
        insert promotions;
        system.debug('########################## PROMOTIONS == '+promotions.size());
        
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Promotion__c p : promotions){
            promotionIds.add(p.Id);
            for(Integer i=0; i<5; i++){
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Environment__c = env1.Id;
                testUserStory.Project__c = testProject.Id;
                testUserStory.Promote_Change__c = true;
                userStories.add(testUserStory);
            }
        }
        insert userStories;
        system.debug('########################## USER STORIES == '+userStories.size());
        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        Integer counter = 0;
        for(User_Story__c u : userStories){
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = u.Id;
            pus.Promotion__c = promotions[counter].Id;
            promotedStories.add(pus);
            counter++;
            if(counter==(promotions.size()-1))counter=0;
        }
        insert promotedStories;
        system.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
        Test.startTest();
        //test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
        //updated to Completed. Then, the User Stories will be updated as well.
        List<Deployment__c> deploys = new List<Deployment__c>();
        for(Promotion__c p : promotions){
            //p.Status__c = 'Completed';
            deploys.add(new Deployment__c(name='test',promotion__c=p.id));
        }
        insert deploys;
        for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
        update deploys;
        

        update promotions;
        Test.stopTest();
        
        List<Promoted_User_Story__c> results = [select Id, User_Story__c, Promotion__c, User_Story__r.Promote_Change__c, User_Story__r.Environment__c, User_Story__r.Org_Credential__c 
                                            from Promoted_User_Story__c
                                            where Promotion__c IN :promotionIds];
        for(Promoted_User_Story__c pus : results){
            system.assertEquals(false, pus.User_Story__r.Promote_Change__c);
            system.assertEquals(env2.Id, pus.User_Story__r.Environment__c);
        }
    }
    


    static testMethod void testRunDestinationTestsUponCompletion(){
	   // "simulate" an API Key, since testmethods do not support webservice callouts inside DeployAPI.createAPIKey();
	   Personal_Settings__c ps = Personal_Settings__c.getInstance();
	   if(String.isBlank(ps.API_Key__c)){
	       ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
	       upsert ps;
	   }
	   system.assert(LicenseHelper.isCopadoEnabled());
	   system.assert(LicenseHelper.isCSTEnabled());

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c env1 = new Environment__c(Name='UAT Environment');
        envList.add(env1);
        Environment__c env2 = new Environment__c(Name='Production Environment');
        envList.add(env2);
        insert envList;

        Release__c testRelease = CMTestMethodUtilities.createRelease('test Release');
        testRelease.Project__c = testProject.Id;
        insert testRelease;

        List<Org__c> orgList = new List<Org__c>();
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        orgList.add(testOrg1);
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        orgList.add(testOrg2);
        insert orgList;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        
        Set<Id> promotionIds = new Set<Id>();
        List<Promotion__c> promotions = new List<Promotion__c>();
        for(Integer i=0; i<5; i++){
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(null, env1.Id);
            testPromotion.Release__c = testRelease.Id;
            promotions.add(testPromotion);
        }
        insert promotions;
        system.debug('########################## PROMOTIONS == '+promotions.size());
        
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Promotion__c p : promotions){
            promotionIds.add(p.Id);
            for(Integer i=0; i<5; i++){
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Environment__c = env1.Id;
                testUserStory.Project__c = testProject.Id;
                testUserStory.Promote_Change__c = true;
                userStories.add(testUserStory);
            }
        }
        insert userStories;
        system.debug('########################## USER STORIES == '+userStories.size());
        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        Integer counter = 0;
        for(User_Story__c u : userStories){
            Promoted_User_Story__c pus = new Promoted_User_Story__c();
            pus.User_Story__c = u.Id;
            pus.Promotion__c = promotions[counter].Id;
            promotedStories.add(pus);
            counter++;
            if(counter>=(promotions.size()-1))counter=0;
        }
        insert promotedStories;
        Test.startTest();
        system.debug('########################## PROMOTED USER STORIES == '+promotedStories.size());
        
        //test that when a deployment linked to promotion is Completed Successfully, the Promotion status is
        //updated to Completed. Then, the User Stories will be updated as well.
        List<Deployment__c> deploys = new List<Deployment__c>();
        for(Promotion__c p : promotions){
            //p.Status__c = 'Completed';
            deploys.add(new Deployment__c(name='test',promotion__c=p.id));
        }
        insert deploys;
        for(Deployment__c d:deploys)d.Status__c='Completed Successfully';
        update deploys;

        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c='http://drive.me');
        insert s;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name='test suite1');
        insert ts1;
        Selenium_Test_Suite__c ts2 = new Selenium_Test_Suite__c(name='test suite2');
        insert ts2;
        
        List<Selenium_Test_Group__c> testgroups = new List<Selenium_Test_Group__c>();
        {
            Selenium_Test_Group__c g;
            
            g = new Selenium_Test_Group__c();
            g.Name = 'source regression';
            g.Selenium_Settings__c = s.Id;
            g.Type__c = 'Regression Test';
            g.Environment__c = testOrg1.Environment__c;
            testgroups.add(g);
            
            g = new Selenium_Test_Group__c();
            g.Name = 'source userstory';
            g.Selenium_Settings__c = s.Id;
            g.Type__c = 'User Story Test';
            g.Environment__c = testOrg1.Environment__c;
            testgroups.add(g);
            
            g = new Selenium_Test_Group__c();
            g.Name = 'dest regression';
            g.Selenium_Settings__c = s.Id;
            g.Type__c = 'Regression Test';
            g.Environment__c = testOrg2.Environment__c;
            testgroups.add(g);
                    
            g = new Selenium_Test_Group__c();
            g.Name = 'dest userstory';
            g.Selenium_Settings__c = s.Id;
            g.Type__c = 'User Story Test';
            g.Environment__c = testOrg2.Environment__c;
            testgroups.add(g);
    
            insert testGroups;
        }
        
        User_Story_Selenium_Test__c usxtest1 = new User_Story_Selenium_Test__c();
        usxtest1.Selenium_Test_Group__c = testgroups.get(1).Id;
        usxtest1.User_Story__c = userStories.get(0).Id;
        insert usxtest1;
        User_Story_Selenium_Test__c usxtest2 = new User_Story_Selenium_Test__c();
        usxtest2.Selenium_Test_Group__c = testgroups.get(3).Id;
        usxtest2.User_Story__c = userStories.get(0).Id;
        insert usxtest2;
        
        System.assertEquals(testOrg1.Environment__c, testgroups.get(0).Environment__c);
        System.assertEquals(testOrg1.Environment__c, testgroups.get(1).Environment__c);
        System.assertEquals(testOrg2.Environment__c, testgroups.get(2).Environment__c);
        System.assertEquals(testOrg2.Environment__c, testgroups.get(3).Environment__c);

        // now get the test groups of each user story
        List<Id> userstoryTestIds = new List<Id>();
        List<Id> promIds = new List<Id>();
        promIds.add(promotions.get(0).Id);
        List<User_Story_Selenium_Test__c> tuss = [select Selenium_Test_Group__c, Selenium_Test_Group__r.Name,
                                                  Selenium_Test_Group__r.Type__c, Selenium_Test_Group__r.Environment__c  
                                                  from User_Story_Selenium_Test__c where User_Story__c in 
                                                  (select User_Story__c from Promoted_User_Story__c where Promotion__c in :promIds)];
        for(User_Story_Selenium_Test__c a : tuss) {
            System.debug('*** '+a);
            
        }
        
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        
        List<id> groupIds = new List<id>();
        for(Selenium_Test_Group__c g1: testgroups ) groupIds.add(g1.Id);
        system.assertEquals(4, groupIds.size());
        

        update promotions;
        Test.stopTest();
        
        testgroups = [select Name, Status__c,Environment__c from Selenium_Test_Group__c where Id IN :groupIds];
        system.assertEquals(4, testgroups.size());
        for(Selenium_Test_Group__c g1 : testgroups )
            System.debug(g1 + ' g1.Status__c='+g1.Status__c);
        for(Selenium_Test_Group__c g1 : testgroups ) {
            if(testOrg1.Environment__c == g1.Environment__c )
	            system.assertEquals(null, g1.Status__c);
            else
	            system.assertEquals('In Progress', g1.Status__c);
        }
	}

    static testMethod void testBackPromotion() {
        Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
        insert feature;
        
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;
        
        Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert envDev1;
        Environment__c envDev2 = new Environment__c(Name='Integration Environment',Type__c='Production');
        insert envDev2;
        Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert envInt;
        
        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        insert orgDev1;
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('MyOrgDev2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envDev2.Id);
        insert orgDev2;
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        insert orgInt;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev2.id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        insert new List<Deployment_Flow_Step__c>{stepDev1ToInt, stepDev2ToInt};

        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.id, Org__c = orgDev1.id, Commit_Id__c='b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c=Date.today().addDays(-3),Commit_Message__c='test 1',Status__c = 'Complete');
        insert snapshotCommit1;


        // Case 1. Dev1 has 1 user story with one 'Complete' commit. UserStory1 appears as 'Ahead' in stepDev1ToInt
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;
        
        User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommit1.id);
        insert userStoryCommit1;

        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotion1.Status__c = 'Completed';
        insert testPromotion1;
        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
        insert promotedUserstory1;
        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Environment__c = envInt.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev2.Id);

        flowCBM.Git_Repository__c = null;
        update flowCBM;

        try {
            insert testBackPromotion1;
            System.assert(false, 'This must fail');
        } catch (Exception e) {
            System.assert(true, e.getMessage().contains(Label.BACK_PROMOTION_NOT_ENABLED));                  
        }

        flowCBM.Git_Repository__c = gitRepo.Id;
        update flowCBM;

        insert testBackPromotion1;
        System.assert(testBackPromotion1.Id != null);
        testBackPromotion1 = [SELECT Id, Name, Source_Environment__c, Destination_Environment__c, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c WHERe Id = :testBackPromotion1.Id];
        System.assertEquals(envInt.Id, testBackPromotion1.Source_Environment__c);
        System.assertEquals(orgInt.Id, testBackPromotion1.Source_Org_Credential__c);
        System.assertEquals(envDev2.Id, testBackPromotion1.Destination_Environment__c);
        System.assertEquals(orgDev2.Id, testBackPromotion1.Destination_Org_Credential__c);
    }

    static testMethod void testDestinationOrgFromEnvironment(){
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        insert testProject;
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId');
        insert env1;
        Org__c testOrg = CMTestMethodUtilities.createOrg('OrgName','Production','','SFDC_OrgId','','USERNAME', System.now(), env1.Id);
        insert testOrg;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('UAT Environment', 'SFDC_OrgId2');
        insert env2;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('OrgName2','Sandbox','','SFDC_OrgId2','','USERNAME2', System.now(), env2.Id);
        insert testOrg2;
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow__c flow2 = CMTestMethodUtilities.createCCMFlow('Standard flow 2', true);
        insert flow2;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        testProject.Deployment_Flow__c = flow.Id;
        update testProject;
        Project__c testProject2 = CMTestMethodUtilities.createProject('test project 2');
        testProject2.Deployment_Flow__c = flow2.Id;
        insert testProject2;

        Release__c release1 = new Release__c(Name = 'Release 1');
        insert release1;
        Release__c release2 = new Release__c(Name = 'Release 2', Project__c = testProject.Id);
        insert release2;
        Release__c release3 = new Release__c(Name = 'Release 3', Project__c = testProject2.Id);
        insert release3;
        
        Test.startTest();
        Promotion__c promotion1 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = testProject.Id, Release__c = release1.Id);
        insert promotion1;
        
        Promotion__c result = [SELECT Id, Source_Environment__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:promotion1.Id LIMIT 1];
        System.assertEquals(testOrg2.Id, result.Destination_Org_Credential__c);

        Promotion__c promotion2 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = testProject.Id, Release__c = release2.Id);
        insert promotion2;

        Promotion__c result2 = [SELECT Id, Source_Environment__c, Destination_Org_Credential__c FROM Promotion__c WHERE Id=:promotion2.Id LIMIT 1];
        System.assertEquals(testOrg2.Id, result2.Destination_Org_Credential__c);

        try {
            Promotion__c promotion3 = new Promotion__c(Source_Environment__c = env1.Id, Project__c = testProject.Id, Release__c = release3.Id);
            insert promotion3;
            throw new ApplicationException('This should fail'); 
        } catch (Exception e) {
            // TODO: Change this error message to a custom label
            System.assertEquals(true, e.getMessage().contains('When both a project and a release are specified in a user story, the deployment flow linked to the project must be the same deployment flow linked to the release project.')); 
        }
        Test.stopTest();
        
    }
}