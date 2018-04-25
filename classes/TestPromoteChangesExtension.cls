@isTest
private class TestPromoteChangesExtension {
    @testSetup
    static void setupData() {
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
        TestUtilities.insertUser('user1-TestPromoteChangesExtension@test-copado.org','System Administrator');
        TestUtilities.assignLicense('user1-TestPromoteChangesExtension@test-copado.org', true, false, true);
        CMTestMethodUtilities.enableSelenium();
    }
    static testMethod void fullTest(){
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Utilities.Secure_DML(env1, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            Utilities.Secure_DML(env2, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Utilities.Secure_DML(testOrg1, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 

            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            insert testOrg2;

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;
            
            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory3'));
            userStories.get(0).Project__c = testProject.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;
            
            userStories.get(1).Project__c = testProject.Id;
            userStories.get(1).Environment__c = env1.Id;
            userStories.get(1).Promote_Change__c = true;
            insert userStories;

            User_Story_Metadata__c usm1 = new User_Story_Metadata__c(Name='US-0006186 CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=userStories[0].Id,Status__c='Potential Conflict');
            insert usm1;
            User_Story_Metadata__c usm2 = new User_Story_Metadata__c(Name='US-0000777 CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=userStories[1].Id,Status__c='Potential Conflict');
            insert usm2;

            Static_Code_Analysis_Result__c scar = new Static_Code_Analysis_Result__c(
            User_Story__c = userStories[0].Id);
            insert scar;
            Static_Code_Analysis_Violation__c vio = new Static_Code_Analysis_Violation__c(
                    Priority__c = 1,
                    Static_Code_Analysis_Result__c = scar.Id);
            insert vio;


            // Manual tasks
            List<Deployment_Task__c> deploymentTasks = new List<Deployment_Task__c>();
            deploymentTasks.add(new Deployment_Task__c(Name='Task1', Perform_in_source_org__c=true, Perform_in_destination_orgs__c=false, Task_description__c='Do this...', User_Story__c=userStories.get(0).Id));
            deploymentTasks.add(new Deployment_Task__c(Name='Task2', Perform_in_source_org__c=false, Perform_in_destination_orgs__c=true, Task_description__c='Do that...', User_Story__c=userStories.get(1).Id));
            insert deploymentTasks;

            // Metadata selections via the grid
            List<Attachment> attachments = new List<Attachment>();
            Attachment att1 = new Attachment(ParentId=userStories.get(0).Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]'));
            Attachment att2 = new Attachment(ParentId=userStories.get(1).Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]'));
            attachments.add(att1);
            attachments.add(att2);
            insert attachments;
            
            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Project__c = testProject.Id;
            testPromotion.Source_Environment__c = env1.Id;
            //testPromotion.Source_Org_Credential__c = testOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = false;
            insert testPromotion;
            testPromotion = [select Id, Release__c, Project__c, Send_Deployment_Complete_email__c, Source_Environment__c, Source_Org_Credential__c, Destination_Org_Credential__c, Back_Promotion__c from Promotion__c where Id =:testPromotion.Id];
            System.debug('#### '+testPromotion);
            
            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.debug('#### Promotion:"'+ext.promotion);
            //ext.listUserStories();
            System.assertEquals(2, ext.userStories.size());
            System.assertEquals(0, ext.getUserStoryMetadatas().size());
            PromoteChangesExtension.getisChatterEnabled();
            
            ext.addStoriesToPromotion();
            system.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();

            //Reload Constructor
            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assertEquals(5, ext.worstSCAscore);
            System.assertEquals(5, ext.averageSCAscore);
            System.assertEquals(2, ext.getUserStoryMetadatas().size());
            
            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            System.assertEquals(0, ext.promotedIdsSet.size());
            
            // now add all again
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(2, ext.promotedIdsSet.size());
        }
        
    }
    static testMethod void fullTestWithRelease(){
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Utilities.Secure_DML(env1, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            Utilities.Secure_DML(env2, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Utilities.Secure_DML(testOrg1, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 

            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            Utilities.Secure_DML(testOrg2, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 

            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);

            testProject.Deployment_Flow__c = flow.Id;        
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.Sobjecttype.Project__c);
            
            Release__c testRelease = CMTestMethodUtilities.createRelease('My Release');
            testRelease.Project__c = testProject.Id;
            Utilities.Secure_DML(testRelease, Utilities.DML_Action.INS, schema.Sobjecttype.Release__c);
            
            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory3'));
            userStories.get(0).Project__c = testProject.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;
            userStories.get(0).Release__c = testRelease.Id;
            
            userStories.get(1).Project__c = testProject.Id;
            userStories.get(1).Environment__c = env1.Id;
            userStories.get(1).Promote_Change__c = true;
            userStories.get(1).Release__c = testRelease.Id;
            Utilities.Secure_DML(userStories, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story__c);
            // Manual tasks
            List<Deployment_Task__c> deploymentTasks = new List<Deployment_Task__c>();
            deploymentTasks.add(new Deployment_Task__c(Name='Task1', Perform_in_source_org__c=true, Perform_in_destination_orgs__c=false, Task_description__c='Do this...', User_Story__c=userStories.get(0).Id));
            deploymentTasks.add(new Deployment_Task__c(Name='Task2', Perform_in_source_org__c=false, Perform_in_destination_orgs__c=true, Task_description__c='Do that...', User_Story__c=userStories.get(1).Id));
            Utilities.Secure_DML(deploymentTasks, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Task__c);

            // Metadata selections via the grid
            List<Attachment> attachments = new List<Attachment>();
            Attachment att1 = new Attachment(ParentId=userStories.get(0).Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]'));
            Attachment att2 = new Attachment(ParentId=userStories.get(1).Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]'));
            attachments.add(att1);
            attachments.add(att2);
            Utilities.Secure_DML(attachments, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
        
            
            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Release__c = testRelease.Id;
            testPromotion.Source_Environment__c = env1.Id;
            //testPromotion.Source_Org_Credential__c = testOrg1.Id;
            testPromotion.Send_Deployment_Complete_email__c = false;
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);
            testPromotion = [select Id, Release__c, Project__c, Send_Deployment_Complete_email__c, Source_Environment__c, Source_Org_Credential__c, Destination_Org_Credential__c, Back_Promotion__c from Promotion__c where Id =:testPromotion.Id];
            system.debug('#### '+testPromotion);
            
            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            system.debug('#### Promotion:"'+ext.promotion);
            //ext.listUserStories();
            system.assertEquals(2, ext.userStories.size());
            
            ext.addStoriesToPromotion();
            system.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            
            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            system.assertEquals(0, ext.promotedIdsSet.size());
            
            // now add all again
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            system.assertEquals(2, ext.promotedIdsSet.size());
        }
    }
    static testMethod void fullTestWarnings() {
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
            Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.Sobjecttype.Feature__c);
            
            Git_Repository__c g = new Git_Repository__c(name = 'g');        
            Utilities.Secure_DML(g, Utilities.DML_Action.INS, schema.Sobjecttype.Git_Repository__c);
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow',true);
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, g.Id, 'master');
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            System.assert(flowCBM.Id != null);
                    
            Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            Utilities.Secure_DML(env1, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
            Utilities.Secure_DML(env2, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Utilities.Secure_DML(testOrg1, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 

            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            Utilities.Secure_DML(testOrg2, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 

            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);

            Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
            dfs4.Branch__c = 'env1';
            Utilities.Secure_DML(dfs4, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);
            System.assert(dfs4.Id != null);
            
            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.Sobjecttype.Project__c);
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);  

            Test.startTest();

            // Success Active CCM Flow
            PageReference pref = Page.PromoteChanges;
            pref.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref);
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext.validateDeployment());

            // Success Valid CBM Flow
            testProject.Deployment_Flow__c = flowCBM.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.Sobjecttype.Project__c);
            flowCBM.Active__c = true;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            PageReference pref2 = Page.PromoteChanges;
            pref2.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref2);
            PromoteChangesExtension ext2 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext2.validateDeployment());

            // Warning Invalid CBM Flow - Main Branch = null
            flowCBM.Main_Branch__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            PageReference pref3 = Page.PromoteChanges;
            pref3.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref3);
            PromoteChangesExtension ext3 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion)); 
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext3.validateDeployment());

            // Warning Invalid CBM Flow - Git Repository = null
            flowCBM.Main_Branch__c = 'master';
            flowCBM.Git_Repository__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            PageReference pref4 = Page.PromoteChanges;
            pref4.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref4);
            PromoteChangesExtension ext4 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));  
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext4.validateDeployment());

            // Warning Inactive CCM Flow
            flow.Active__c = false;
            Utilities.Secure_DML(flow, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c); 
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.Sobjecttype.Project__c);
            PageReference pref5 = Page.PromoteChanges;
            pref5.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref5);
            PromoteChangesExtension ext5 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assert(!ext5.validateDeployment());

            Test.stopTest();
        }
    }
    static testMethod void fullTestWarningsCCM() {
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
            Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.Sobjecttype.Feature__c);     
            
            Git_Repository__c g = new Git_Repository__c(name = 'g');
            Utilities.Secure_DML(g, Utilities.DML_Action.INS, schema.Sobjecttype.Git_Repository__c);
            Deployment_Flow__c flow = CMTestMethodUtilities.createFlow('simple flow');
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', false, g.Id, 'master');
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            System.assert(flowCBM.Id != null);
                    
            Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
            Utilities.Secure_DML(env1, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c);
            Environment__c env2 = new Environment__c(Name='Integration Environment',Type__c='Production');
            Utilities.Secure_DML(env2, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c);
            Environment__c env3 = new Environment__c(Name='UAT Environment',Type__c='Sandbox');
            Utilities.Secure_DML(env3, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c);
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Utilities.Secure_DML(testOrg1, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            Utilities.Secure_DML(testOrg2, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 
            
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);
            Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
            dfs2.Branch__c = 'env1';
            Utilities.Secure_DML(dfs2, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);

            flowCBM.Active__c = true;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            
            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flowCBM.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.Sobjecttype.Project__c);
            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);

            Test.startTest();

            System.debug('#Message Copado License: '+LicenseHelper.isCopadoEnabled());

            // Success Valid CBM Flow
            PageReference pref = Page.PromoteChanges;
            pref.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref);
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.assert(ApexPages.getMessages().size() == 0);
            System.assert(ext.validateDeployment());

            // Copado License: Warning Invalid CBM Flow - Main Branch = null
            flowCBM.Main_Branch__c = null;
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            PageReference pref2 = Page.PromoteChanges;
            pref2.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref2);
            PromoteChangesExtension ext2 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));    
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext2.validateDeployment());

            // Copado License: Warning Invalid CBM Flow - Git Repository = null
            flowCBM.Git_Repository__c = null;
            flowCBM.Main_Branch__c = 'master';
            Utilities.Secure_DML(flowCBM, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow__c);
            PageReference pref3 = Page.PromoteChanges;
            pref3.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref3);
            PromoteChangesExtension ext3 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));    
            System.assert(testMethodUtilities.hasMessage(Label.CBM_FLOW_INVALID));
            System.assert(!ext3.validateDeployment());

            // Warning Inactive CCM Flow
            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.UPD, schema.Sobjecttype.Project__c); 
            PageReference pref4 = Page.PromoteChanges;
            pref4.getParameters().put('id',testPromotion.id);
            Test.setCurrentPage(pref4);
            PromoteChangesExtension ext4 = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));    
            System.assert(testMethodUtilities.hasMessage(Label.PROMOTION_FLOW_INACTIVE));
            System.assert(!ext4.validateDeployment());   
            Test.stopTest();
        }
    }
    static testMethod void testWithSelenium(){
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c='http://drive.me');
        Utilities.Secure_DML(s, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Settings__c);
        Feature__c f = new Feature__c(Name='Selenium Testing', Enabled__c=true, Quantity__c=10);
        Utilities.Secure_DML(f, Utilities.DML_Action.INS, schema.Sobjecttype.Feature__c);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            // Copado
            Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
            Utilities.Secure_DML(env1, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
            Utilities.Secure_DML(env2, Utilities.DML_Action.INS, schema.Sobjecttype.Environment__c); 
            
            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Utilities.Secure_DML(testOrg1, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c); 
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            Utilities.Secure_DML(testOrg2, Utilities.DML_Action.INS, schema.Sobjecttype.Org__c);       
        
            // Selenium         
            Selenium_Test_Group__c g1 = new Selenium_Test_Group__c(Name = 'source regression group',Selenium_Settings__c = s.id,Type__c = 'Regression Test', Environment__c=env1.Id);
            Utilities.Secure_DML(g1, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Group__c);
            Selenium_Test_Group__c g2 = new Selenium_Test_Group__c(Name = 'destination regression group',Selenium_Settings__c = s.id,Type__c = 'Regression Test', Environment__c=env2.Id);
            Utilities.Secure_DML(g2, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Group__c);
            Selenium_Test_Group__c g3 = new Selenium_Test_Group__c(Name = 'source user story group',Selenium_Settings__c = s.id,Type__c = 'User Story Test', Environment__c=env1.Id);
            Utilities.Secure_DML(g3, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Group__c);
            Selenium_Test_Group__c g4 = new Selenium_Test_Group__c(Name = 'destination user story group',Selenium_Settings__c = s.id,Type__c = 'User Story Test', Environment__c=env2.Id);
            Utilities.Secure_DML(g4, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Group__c);
            
            Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name='test suite1');
            Utilities.Secure_DML(ts1, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Suite__c);
            
            Selenium_Group_Org_Credential__c goc1 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g1.Id, Org_Credential__c = testOrg1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(goc1, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Org_Credential__c);
            Selenium_Group_Org_Credential__c goc2 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g2.Id, Org_Credential__c = testOrg2.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(goc2, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Org_Credential__c);
            Selenium_Group_Org_Credential__c goc3 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g3.Id, Org_Credential__c = testOrg1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(goc3, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Org_Credential__c);
            Selenium_Group_Org_Credential__c goc4 = new Selenium_Group_Org_Credential__c(Selenium_Test_Group__c = g4.Id, Org_Credential__c = testOrg2.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(goc4, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Org_Credential__c);
            
            Selenium_Group_Test_Suite__c gts1 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g1.Id, Selenium_Test_Suite__c = ts1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(gts1, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Test_Suite__c);
            System.assertEquals(1, [select count() from Selenium_Test_Run__c where Selenium_Test_Group__c = :g1.Id]);
            
            Selenium_Group_Test_Suite__c gts2 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g2.Id, Selenium_Test_Suite__c = ts1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(gts2, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Test_Suite__c);
            System.assertEquals(1, [select count() from Selenium_Test_Run__c where Selenium_Test_Group__c = :g2.Id]);
            
            Selenium_Group_Test_Suite__c gts3 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g3.Id, Selenium_Test_Suite__c = ts1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(gts3, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Test_Suite__c);
            System.assertEquals(1, [select count() from Selenium_Test_Run__c where Selenium_Test_Group__c = :g3.Id]);
            
            Selenium_Group_Test_Suite__c gts4 = new Selenium_Group_Test_Suite__c(Selenium_Test_Group__c = g4.Id, Selenium_Test_Suite__c = ts1.id);
            SeleniumTestRunTriggerHelper.inTrigger = false;
            Utilities.Secure_DML(gts4, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Group_Test_Suite__c);
            System.assertEquals(1, [select count() from Selenium_Test_Run__c where Selenium_Test_Group__c = :g4.Id]);
            
            // CCM
            Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
            //TestUtilities.enableLicenses(10, 10, 10);
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);        
            Utilities.Secure_DML(flow, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow__c);
            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            Utilities.Secure_DML(dfs, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_Flow_Step__c);

            testProject.Deployment_Flow__c = flow.Id;
            Utilities.Secure_DML(testProject, Utilities.DML_Action.INS, schema.Sobjecttype.Project__c);

            
            List<User_Story__c> userStories = new List<User_Story__c>();
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory1'));
            userStories.add(CMTestMethodUtilities.createUserStory('MyStory2'));
            userStories.get(0).Project__c = testProject.Id;
            userStories.get(0).Environment__c = env1.Id;
            userStories.get(0).Promote_Change__c = true;
            
            userStories.get(1).Project__c = testProject.Id;
            userStories.get(1).Environment__c = env1.Id;
            userStories.get(1).Promote_Change__c = true;
            Utilities.Secure_DML(userStories, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story__c);


            List<User_Story_Selenium_Test__c> usST = new List<User_Story_Selenium_Test__c>();
            usST.add(new User_Story_Selenium_Test__c(Name='us1 Source Env Test Group', User_Story__c=userStories.get(0).Id, Selenium_Test_Group__c=g3.Id));
            usST.add(new User_Story_Selenium_Test__c(Name='us2 Destination Env Test Group', User_Story__c=userStories.get(1).Id, Selenium_Test_Group__c=g4.Id));
            Utilities.Secure_DML(usST, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story_Selenium_Test__c);

            Promotion__c testPromotion = new Promotion__c();
            testPromotion.Project__c = testProject.Id;
            testPromotion.Source_Environment__c = env1.Id;
            Utilities.Secure_DML(testPromotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);
            testPromotion = [select Id, Release__c, Project__c, Send_Deployment_Complete_email__c, Source_Environment__c, Source_Org_Credential__c, Destination_Org_Credential__c, Back_Promotion__c from Promotion__c where Id =:testPromotion.Id];
            
            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            system.assertEquals(2, ext.userStories.size());
            //System.assertEquals(1, ext.SourceRegressionSeleniumTests.size());
            //System.assertEquals(1, ext.DestinationRegressionSeleniumTests.size());
            
            ext.userStories[0].selected = true;
            ext.userStories[1].selected = true;
            ext.addStoriesToPromotion();
            system.assertEquals(2, ext.promotedIdsSet.size());
            ext.getSeleniumTestGroups();
            //System.assertEquals(1, ext.SourceRegressionSeleniumTests.size());
            //System.assertEquals(1, ext.DestinationRegressionSeleniumTests.size());
            //System.assertEquals(1, ext.SourceUserStorySeleniumTests.size());
            //System.assertEquals(1, ext.DestinationUserStorySeleniumTests.size());
                    
            // now remove all user stories
            ext.promotedWrappedStories[0].selected = true;
            ext.promotedWrappedStories[1].selected = true;
            ext.removeSelectedUserStories();
            system.assertEquals(0, ext.promotedIdsSet.size());
            ext.getSeleniumTestGroups();
            //System.assertEquals(1, ext.SourceRegressionSeleniumTests.size());
            //System.assertEquals(1, ext.DestinationRegressionSeleniumTests.size());
            //System.assertEquals(0, ext.SourceUserStorySeleniumTests.size());
            //System.assertEquals(0, ext.DestinationUserStorySeleniumTests.size());

            System.Test.setCurrentPage(new PageReference('/'));
            ext.recalcSeleniumTestGroups();
            System.assertEquals(false, ext.getIsSeleniumRunning());
            Test.stopTest();
        }
    }
    static testMethod void testBackPromotion(){
        Feature__c feature = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=10);
        insert feature;
        
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
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

            Test.startTest();
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

            Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev2.Id);

            insert testBackPromotion1;
            
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testBackPromotion1));
            System.assertEquals(1, ext.userStories.size());
            ext.addStoriesToPromotion();
            System.assert(testMethodUtilities.hasMessage(Label.NO_USER_STORIES_TO_PROMOTE));
            ext.userStories[0].selected = true;
            ext.addStoriesToPromotion();
            System.assertEquals(1, ext.promotedIdsSet.size());
        }
    }
    static testMethod void testUSMetadatas(){
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c); 
        //TestUtilities.enableLicenses(10, 10, 10);

        User user = [SELECT Id FROM User WHERE Username = 'user1-TestPromoteChangesExtension@test-copado.org' LIMIT 1];

        System.runAs(user) {
            Project__c testProject = CMTestMethodUtilities.createProject('My Project');
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
            insert testProject;
            
            User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory ');
            userStory.Project__c = testProject.Id;
            userStory.Environment__c = env1.Id;
            userStory.Promote_Change__c = true;
            insert userStory;

            List<User_Story_Metadata__c> userStoryMetadatas = new List<User_Story_Metadata__c>();
            for(Integer i=0; i<5200; i++) {
                User_Story_metadata__c usMetadata = new User_Story_Metadata__c(Name='US-'+i+' CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=userStory.Id,Status__c='Potential Conflict');
                userStoryMetadatas.add(usMetadata);
            }
            insert userStoryMetadatas;

            userStoryMetadatas = new List<User_Story_Metadata__c>();
            for(Integer i=0; i<4000; i++) {
                User_Story_metadata__c usMetadata = new User_Story_Metadata__c(Name='US-'+i+' CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=userStory.Id,Status__c='Potential Conflict');
                userStoryMetadatas.add(usMetadata);
            }
            insert userStoryMetadatas;

            Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
            insert testPromotion;

            Test.startTest();
            PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            System.debug('#### Promotion:"'+ext.promotion);
            //ext.listUserStories();
            System.assertEquals(1, ext.userStories.size());
            System.assertEquals(0, ext.getUserStoryMetadatas().size());

            ext.userStories[0].selected = true;
            ext.addStoriesToPromotion();

            //Reload Constructor
            ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
            Integer metadatasSize = ext.getUserStoryMetadatas().size();
            System.debug('### UserStoryMetadatas size: '+metadatasSize);
            System.assert(true, metadatasSize < 9201);
            Test.stopTest();
        }
    }
    static testMethod void testBaseBranchValidation(){
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c env1 = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId');
        insert env1;
        Environment__c env2 = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId2');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        flow.Auto_Resolve_Options__c = 'All except code';
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;

        Release__c release = new Release__c(Name = 'Release 1');
        insert release;

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('MyStory 1');
        userStory1.Project__c = testProject.Id;
        userStory1.Environment__c = env1.Id;
        userStory1.Promote_Change__c = true;
        insert userStory1;

        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('MyStory 2');
        userStory2.Project__c = testProject.Id;
        userStory2.Environment__c = env1.Id;
        userStory2.Promote_Change__c = true;
        insert userStory2;

        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        testPromotion.Release__c = release.Id;
        insert testPromotion;
        List<Promotion__c> promotions = new List<Promotion__c>();
        promotions = [SELECT Id, Project__c, Source_Environment__c, Auto_Resolve_Options__c FROM Promotion__c WHERE Id = :testPromotion.Id];
        System.assert(promotions.size() > 0);
        System.assertEquals('All except code', promotions[0].Auto_Resolve_Options__c);

        Promoted_User_Story__c pus1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion.Id);
        insert pus1;
        Promoted_User_Story__c pus2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotion.Id);
        insert pus2;

        Test.startTest();
        PromoteChangesExtension ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
        System.assertEquals(2, ext.promotedWrappedStories.size());
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT));

        release.Base_Branch__c = 'int';
        update release;

        ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
        System.assertEquals(2, ext.promotedWrappedStories.size());
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT));

        userStory1.Base_Branch__c = 'patch5';
        update userStory1;

        ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
        System.assertEquals(2, ext.promotedWrappedStories.size());
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStory1.Name));

        userStory2.Base_Branch__c = 'patch7';
        update userStory2;

        ext = new PromoteChangesExtension(new ApexPages.StandardController(testPromotion));
        System.assertEquals(2, ext.promotedWrappedStories.size());
        System.assertEquals(false, testMethodUtilities.hasMessage(Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStory1.Name + ', ' + userStory2.Name));

        Test.stopTest();
    }
}