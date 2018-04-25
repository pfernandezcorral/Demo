/**
 * Created by ferhatozsavran on 2/28/18.
 */

@isTest
private class  TestCreateUSScratchOrg {

    @testSetup static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @isTest static void createUserStoryScratchOrg(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [Select Id,Name, Org_Credential__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getMyComponentController();

        ScratchOrgController socController = new ScratchOrgController();
        socController.componentMode = 'wizard';
        socController.showTemplateButtons = false;
        socController.showButtons = true;
        socController.pageController = controller;
        socController.controllerKey = 'ScratchOrgTemplate';

        controller.nextStep(); // it will return because dev hub org id is not selected

        socController.orgTemplate.orgName = 'FO test';

        Org__c devHubOrg = [Select Id From Org__c Where Name =: 'Dev Hub 1'];
        socController.devHubOrgId = devHubOrg.Id;

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'wizard';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.pageController = controller;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.typeName = 'branch';
        somcController.showPatchOptions = false;

        //Select git repository and populate grid panel
        Git_Repository__c gr = [Select Id, Name From Git_Repository__c Where Name =: 'git 1'];
        somcController.repoId = gr.Id;
        somcController.repoName = gr.Name;

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [Select Id, Branch__c From Git_Backup__c Where Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);

        controller.nextStep();
        system.assertEquals('COMPLETE',controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.componentMode = 'wizard';
        soccController.showTemplateButtons = false;
        soccController.showButtons = true;
        soccController.pageController = controller;
        soccController.controllerKey = 'ScratchOrgCompletion';

        soccController.createFullScratchOrg();
        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();
        Test.stopTest();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();
    }

    @isTest static void scratchOrgOpen(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.ScratchOrgOpen;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];

        Copado_Notification__c cn = new Copado_Notification__c();
        cn.Type__c = CopadoNotificationHelper.DX_OPEN_ORG;
        cn.OwnerId = UserInfo.getUserId();
        cn.isFinished__c = false;
        cn.ParentId__c = orgScratch.Id;
        cn.Matching_Key__c = 'testmatching';
        insert cn;

        pageRef.getParameters().put('id',orgScratch.Id);

        //Instantiate and construct the controller class of DX Operation page.
        ScratchOrgOpen sooController = new ScratchOrgOpen();

        system.assertEquals(null,sooController.copadoJobFinished);

        //Open scratch org
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCopadoId = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoId);
        sooController.rScratchOrgJob();
        Test.stopTest();
    }
}