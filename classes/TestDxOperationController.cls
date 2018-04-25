/**
 * Created by ferhatozsavran on 2/2/18.
 */
@isTest
private class  TestDxOperationController {

    @testSetup static void setup(){
        // Create common test records
        insert TestUtilities.getTestSettings();

        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    //Load metadata, load data and commit history is tested at scratchorgoperationone for artifacts
    @isTest static void scratchOrgOperationsOne(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'ch');
        controller.enableSelectedPanels();

        //Check the snapshot commit list size
        system.assertEquals(0,controller.snapshotCommitList.size());

        //Return main menu to process another operation
        ApexPages.currentPage().getParameters().put('actionName', 'main');
        controller.enableSelectedPanels();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select artifact and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'artifact');
        somcController.selectType();

        //Select Project template and fill org credential and artifacts
        Scratch_Org_Project_Template__c sopt = [Select Id From Scratch_Org_Project_Template__c Where Name =: 'Test'];
        ApexPages.currentPage().getParameters().put('templateId', sopt.Id);
        somcController.readProjectTemplate();

        //Click to the load metadata button. Set mock callout class
        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        somcController.loadMetadata();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_LOAD_METADATA);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    //org status is tested at scratchorgoperationtwo (copado notification is not created before call out)
    @isTest static void scratchOrgOperationsTwo(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select org status from action and open org status component
        ApexPages.currentPage().getParameters().put('actionName', 'gsos');

        //Instantiate and construct the controller class of component.
        ScratchOrgStatusCtrl soscController = new ScratchOrgStatusCtrl();

        //Assign selected scratch org id to the attribute of component
        soscController.soOrgId = orgScratch.Id;
        String orgSelected = soscController.orgSelected; //to trigger the set

        //Fill the scratch org variable
        soscController.orgChanged();

        //Check if scratch is active or not
        soscController.getIsActive();

        //Check if environment has git repository or not
        soscController.getHasRepo();

        //Click to the check status button
        soscController.requestStatus(); //it failed and covered  the catch

        //Set mock callout class and click to the check status button
        Test.startTest();
        MockHttpResponseGenerator fakeResponseError = new MockHttpResponseGenerator(200,'Complete','{"copadoJobId":"","ok":"","status":"","error":"There is test error"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseError);
        soscController.requestStatus();

        MockHttpResponseGenerator fakeResponseCopadoId = new MockHttpResponseGenerator(200,'Complete','{"copadoJobId":"123456789012345678","ok":"","status":"","error":""}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoId);
        soscController.requestStatus();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'false');
        ApexPages.currentPage().getParameters().put('jobMessage', 'Error');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_SOURCE_STATUS);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    //org status is tested at scratchorgoperationthree (copado notification is created before call out)
    @isTest static void scratchOrgOperationsThree(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select org status from action and open org status component
        ApexPages.currentPage().getParameters().put('actionName', 'gsos');

        //Instantiate and construct the controller class of component.
        ScratchOrgStatusCtrl soscController = new ScratchOrgStatusCtrl();

        //Assign selected scratch org id to the attribute of component
        soscController.soOrgId = orgScratch.Id;
        String orgSelected = soscController.orgSelected; //to trigger the set

        //Fill the scratch org variable
        soscController.orgChanged();

        //Check if scratch is active or not
        soscController.getIsActive();

        //Check if environment has git repository or not
        soscController.getHasRepo();

        //Set mock callout class and click to the check status button
        Test.startTest();
        Copado_Notification__c cn = new Copado_Notification__c();
        cn.Type__c = CopadoNotificationHelper.DX_SOURCE_STATUS;
        cn.OwnerId = UserInfo.getUserId();
        cn.isFinished__c = false;
        cn.ParentId__c = soscController.soOrgId;
        cn.Matching_Key__c = 'testmatching';
        insert cn;

        MockHttpResponseGenerator fakeResponseCopadoId = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoId);
        soscController.requestStatus();

        cn.isFinished__c = true;
        cn.isSuccess__c = true;
        update cn;

        MockHttpResponseGenerator fakeResponseCopadoIds = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoIds);
        soscController.retrieveStatus();

        cn.isSuccess__c = false;
        update cn;

        MockHttpResponseGenerator fakeResponseCopadoIds1 = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoIds1);
        soscController.retrieveStatus();

        Test.stopTest();

        //Fill all org credentials
        List<SelectOption> orgOptionList = soscController.allScratchOrgs;
    }

    //display org component is tested at scratchorgoperationfour
    @isTest static void scratchOrgOperationsFour(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Click Display scratch org button. Instantiate and construct the controller class of component.
        ScratchOrgDisplayController sodcController = new ScratchOrgDisplayController();

        //Populate the attribute of the component, it will cover catch because scratch org do not have attachment with name ScratchOrgDisplay.json
        sodcController.scratchOrgId = orgScratch.Id;

        //Select the Scratch Org 2 from picklist and populate actions
        Org__c orgScratch1 = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2'];
        controller.selectedOperationDataId = orgScratch1.Id;
        controller.populatePossibleActions();

        //Click Display scratch org button. Instantiate and construct the controller class of component.
        ScratchOrgDisplayController sodcController1 = new ScratchOrgDisplayController();

        //Populate the attribute of the component
        sodcController1.scratchOrgId = orgScratch1.Id;

        //Set mock callout class and click to the click delete scratch org button
        Test.startTest();
        MockHttpResponseGenerator fakeResponseDeleteScratchOrg = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseDeleteScratchOrg);
        sodcController1.deleteScratchOrg();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_DELETE_ORG);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    //Load metadata, load data and commit history is tested at scratchorgoperationone for branch
    @isTest static void scratchOrgOperationsFive(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'branch');
        somcController.selectType();

        //Select git repository and populate grid panel
        Git_Repository__c gr = [Select Id, Name From Git_Repository__c Where Name =: 'git 1'];
        somcController.repoId = gr.Id;
        somcController.repoName = gr.Name;
        somcController.getSfdxFormat();

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [Select Id, Branch__c From Git_Backup__c Where Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('brancName', gb.Branch__c);
        DXOperationController newController = new DXOperationController();
        newController.setBranchName();

        //Click to the load metadata button. Set mock callout class
        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        somcController.loadMetadata();
        Test.stopTest();
    }

    //Load metadata, load data and commit history is tested at scratchorgoperationone for org
    @isTest static void scratchOrgOperationsSix(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Org'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'org');
        somcController.selectType();
        somcController.showPatchOptions = false;

        //Populate version picklist
        somcController.getVersions();

        //Populate org credential picklist and select one of the org credential
        somcController.getOrgCredentialsList();
        Org__c orgScratchForOrg = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 1'];
        somcController.sourceSelections = orgScratchForOrg.Id;

        //Click to the load metadata button. Set mock callout class
        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        somcController.loadMetadata();
        Test.stopTest();
    }

    //optional operation for org scratch org
    @isTest static void scratchOrgOperationsSeven(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Name, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Org'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'ld');
        controller.enableSelectedPanels();

        //Populate deployment picklist based on selected source org
        controller.sourceOrgId = orgScratch.Id;
        controller.sourceOrgName = orgScratch.Name;
        controller.populateDeployments();

        //Select deployment and init the cloning
        Deployment__c deployment = [Select Id From Deployment__c Where Name =: 'Deployment'];
        controller.selectedDeploymentId = deployment.Id;
        controller.initDeploymentStep();

        //Redirect to the deployment page
        controller.executeSteps();
    }

    @isTest static void scratchOrgOperationsEight(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'branch');
        somcController.selectType();

        //Refresh the repo cache and Select git repository and populate grid panel
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCache = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCache);
        Git_Repository__c gr = [Select Id, Name From Git_Repository__c Where Name =: 'git 1'];
        somcController.repoId = gr.Id;
        somcController.repoName = gr.Name;
        somcController.refreshBranchCache();
        Test.stopTest();
    }

    @isTest static void scratchOrgOperationsNine(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'patch');
        somcController.selectType();

        //Select the release
        somcController.setRepo(); // this will give an error. No release is selected
        Release__c release = [Select Id From Release__c Where Name =: 'Release 1'];
        somcController.releaseId = release.Id;
        somcController.setRepo(); //Version, base branch and project of selected release is empty
        Release__c release1 = [Select Id From Release__c Where Name =: 'Release 2'];
        somcController.releaseId = release1.Id;
        somcController.setRepo();

        //Refresh the repo cache and Select git repository and populate grid panel
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCache = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCache);
        somcController.loadMetadata();
        Test.stopTest();
    }

    @isTest static void scratchOrgOperationsTen(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'artifactUMP');
        somcController.selectType();

        //Select the Scratch Org 2 For Branch from picklist and populate actions
        Org__c orgScratch1 = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        somcController.orgId = orgScratch1.Id;

        //Refresh the package cache
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCache = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCache);
        somcController.refreshPackagesCache();
        Test.stopTest();
    }

    @isTest static void scratchOrgOperationsEleven(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.componentMode = 'add';
        somcController.showTemplateButtons = false;
        somcController.showButtons = true;
        somcController.controllerKey = 'ScratchOrgMetadata';
        somcController.pageController = controller;

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('typeName', 'artifactUMP');
        somcController.selectType();

        //Select the Scratch Org 2 For Branch from picklist and populate actions
        Org__c orgScratch1 = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org 2 For Branch'];
        somcController.orgId = orgScratch1.Id;

        //Refresh the package cache
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCache = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCache);
        somcController.loadMetadata();
        Test.stopTest();
    }

    @isTest static void scratchOrgOperationsTwelve(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org Branch 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Instantiate and construct the controller class of component.
        ScratchOrgDisplayController sodcController = new ScratchOrgDisplayController();

        //Populate the attribute of the component, it will cover catch because scratch org do not have attachment with name ScratchOrgDisplay.json
        sodcController.scratchOrgId = orgScratch.Id;

        //Set mock callout class and click to the click delete scratch org button
        Test.startTest();
        MockHttpResponseGenerator fakeResponseDeleteScratchOrg = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseDeleteScratchOrg);
        sodcController.generatePassword();

        //run the event listener job for load metadata job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_ORG_IDE_DETAILS);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @isTest static void scratchOrgOperationsThirteen(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Scratch Org Operations and execute the change function
        controller.selectedOperation = '1';
        controller.resetDom();

        //Check the map size
        system.assertEquals(6,controller.objectNameMap.size());

        //Select the Scratch Org 1 from picklist and populate actions
        Org__c orgScratch = [Select Id, Environment__c From Org__c Where Name =: 'Scratch Org Branch 1'];
        controller.selectedOperationDataId = orgScratch.Id;
        controller.populatePossibleActions();

        //Instantiate and construct the controller class of component.
        ScratchOrgDisplayController sodcController = new ScratchOrgDisplayController();

        //Populate the attribute of the component, it will cover catch because scratch org do not have attachment with name ScratchOrgDisplay.json
        sodcController.scratchOrgId = orgScratch.Id;

        //Set mock callout class and click to the click delete scratch org button
        Test.startTest();
        MockHttpResponseGenerator fakeResponseDeleteScratchOrg = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseDeleteScratchOrg);
        sodcController.orgDetails();
        Test.stopTest();
    }

    @isTest static void devHubOperations(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Dev Hub Operations and execute the change function
        controller.selectedOperation = '2';
        controller.resetDom();

        //Check the map size
        system.assertEquals(1,controller.objectNameMap.size());

        //Select the Dev Hub 1 from picklist and populate actions
        Org__c orgDevHub = [Select Id From Org__c Where Name =: 'Dev Hub 1'];
        controller.selectedOperationDataId = orgDevHub.Id;
        controller.populatePossibleActions();

        //Select manage scratch org from action and fill scratch org lists
        ApexPages.currentPage().getParameters().put('actionName', 'mso');
        controller.enableSelectedPanels();

        //Check the list sizes
        system.assertEquals(1,controller.activeScratchOrgList.size());
        system.assertEquals(1,controller.deletedScratchOrgList.size());

        //Select create scratch org from action and it will load the Scratch Org Template component
        ApexPages.currentPage().getParameters().put('actionName', 'cso');
        controller.enableSelectedPanels();

        //Instantiate and construct the controller class of component.
        ScratchOrgController socController = new ScratchOrgController();
        socController.componentMode = 'new';
        socController.showTemplateButtons = true;
        socController.showButtons = true;
        socController.controllerKey = 'ScratchOrgTemplate';
        socController.pageController = controller;

        controller.getMyComponentController();
        controller.setComponentController(socController);

        //Load template with selected hub id
        socController.getTemlatesWithHubId();

        //Check the list sizes and it holds (-- None --) and (sod id)
        system.assertEquals(2,socController.getTemlatesWithHubId().size());

        //Select definition template and load details.
        Scratch_Org_Definition__c sod = [Select Id, Scratch_Org_Definition_JSON__c From Scratch_Org_Definition__c Where Name =: 'Scratch Org Definition'];
        socController.templateId = sod.Id;
        socController.readOrgDefinitionFromTemplate();

        //Enable and Disable org preferences
        socController.selectedPreferenceType = 'General Setting';
        socController.setLastSelection();

        //Click to Save as Template button and try to create new template
        socController.newTemplate();

        //Click to Save as Template button and try to update template
        socController.updateTemplate();

        //Click to Create Scratch Org button
        socController.createOrg(); // returned error because org name is empty
        socController.orgTemplate.orgName = 'FO test';
        socController.duration = 40;
        socController.createOrg(); // returned error because duration is out of range
        socController.duration = 20;
        socController.orgTemplate.edition = null;
        socController.createOrg(); // returned error because edition is null
        socController.orgTemplate.edition = 'Developer';

        //Select deployment flow, populate deployment flow steps and select deployment flow steps
        socController.getDeploymentFlows();

        //Select deployment flow and populate deployment flow steps
        Deployment_Flow__c df = [Select Id From Deployment_Flow__c Where Name =: 'Deployment Flow 1'];
        socController.deploymentFlowId = df.Id;
        socController.populateDeploymentFlowSteps();

        //Select the deployment flow step to create org
        Deployment_Flow_Step__c dfs = [Select Id From Deployment_Flow_Step__c Where Deployment_Flow__r.Name =: 'Deployment Flow 1' AND Enable_as_Scratch_Org_Destination__c =: 'Default DX Target'];
        socController.deploymentFlowStepOption = dfs.Id;

        //Set mock callout class
        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        socController.createOrg();

        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_ORG);
        controller.jobStatusNotification();
        Test.stopTest();
    }

    @isTest static void userStoryOperationsOne(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select User Story Operations and execute the change function
        controller.selectedOperation = '3';

        //Select the user story from lookup and populate actions. It will return because us do not belong to project and deployment flow is null
        User_Story__c uStory = [Select Id, User_Story_Title__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation'];
        controller.usId = uStory.Id;
        controller.usName = uStory.User_Story_Title__c;
        controller.populatePossibleActions();

        //Select the user story from lookup and populate actions. It will return becuase deployment flow step size is 0
        User_Story__c uStory1 = [Select Id, User_Story_Title__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation 1'];
        controller.usId = uStory1.Id;
        controller.usName = uStory1.User_Story_Title__c;
        controller.populatePossibleActions();

        //Select the user story from lookup and populate actions
        User_Story__c uStory2 = [Select Id, User_Story_Title__c, Org_Credential__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation 2'];
        controller.usId = uStory2.Id;
        controller.usName = uStory2.User_Story_Title__c;
        controller.populatePossibleActions();

        //Select commit history from action and load snapshots commit
        ApexPages.currentPage().getParameters().put('actionName', 'ch');
        controller.enableSelectedPanels();

        //Check the user story commit list size
        system.assertEquals(0,controller.userStoryCommitList.size());

        //Select load data from action and load data
        ApexPages.currentPage().getParameters().put('actionName', 'ld');
        controller.enableSelectedPanels();

        //Select load metadata from action. It will return becuase org type of the user story is not Scratch org
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();
    }

    //Load metadata is covered for user story operation
    @isTest static void userStoryOperationsTwo(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select User Story Operations and execute the change function
        controller.selectedOperation = '3';

        //Select the user story from lookup and populate actions
        User_Story__c uStory3 = [Select Id, User_Story_Title__c, Org_Credential__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation 3'];
        controller.usId = uStory3.Id;
        controller.usName = uStory3.User_Story_Title__c;
        controller.populatePossibleActions();

        //Select load metadata from action.
        ApexPages.currentPage().getParameters().put('actionName', 'lm');
        controller.enableSelectedPanels();

        //check the value
        system.assertEquals('lm',controller.selectedActionName);

        //Select create scratch org action to get warning
        ApexPages.currentPage().getParameters().put('actionName', 'csous');
        controller.enableSelectedPanels();

        //check the value
        system.assertEquals('csous',controller.selectedActionName);
    }

    @isTest static void planningOperationsOne() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';
        controller.resetDom();

        //Select manage artifact from action
        ApexPages.currentPage().getParameters().put('actionName', 'ma');
        controller.enableSelectedPanels();

        //Select the Dev Hub 1 from picklist and populate artifact lists
        Org__c orgDevHub = [Select Id From Org__c Where Name =: 'Dev Hub 1'];
        controller.selectedOperationDataId = orgDevHub.Id;
        controller.retrieveArtifacts();

        //check the list size
        system.assertEquals(1,controller.artifactList.size());

        //Instantiate and construct the controller class of ArtifactManageMetadata page.
        Artifact__c art = [Select Id, Artifact_Repository__c, Org_Credential__c From Artifact__c Where Name =: 'StaticResources2'];
        PageReference pageAmm = Page.ArtifactManageMetadata;
        Test.setCurrentPage(pageAmm);
        pageAmm.getParameters().put('Id', art.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(art);

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        ArtifactManageMetadataController ammController = new ArtifactManageMetadataController(sc);

        //MockHttpResponseGenerator fakeResponseError = new MockHttpResponseGenerator(200,'Complete','{"copadoJobId":"","ok":"","status":"","error":"There is test error"}',null);
        //Test.setMock(HttpCalloutMock.class, fakeResponseError);
        ammController.callJob();
        Test.stopTest();
    }

    @isTest static void planningOperationsTwo() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Select Planning Operations and execute the change function
        controller.selectedOperation = '4';
        controller.resetDom();

        //Select manage manage definition template and execute function
        ApexPages.currentPage().getParameters().put('actionName', 'mpt');
        controller.enableSelectedPanels();

        //Check the action name
        system.assertEquals('mpt',controller.selectedActionName);

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somController = new ScratchOrgMetadataController();
        somController.componentMode = 'template';
        somController.showTemplateButtons = true;
        somController.showButtons = false;
        somController.controllerKey = 'ScratchOrgMetadata';
        somController.pageController = controller;

        //Click to Save as Template button. It will return because template name is empty
        somController.newTemplate();

        //Fill template name and Click Save as Template button again
        somController.templateName = 'New Template';
        somController.newTemplate();

    }

    @isTest static void existingOrgIdOperations() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Select the Dev Hub 1
        Org__c orgDevHub = [Select Id From Org__c Where Name =: 'Dev Hub 1'];

        //Assign the dev hub id to the page as a parameter
        pageRef.getParameters().put('id', orgDevHub.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef1 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef1);

        //Select the wrong scratch org
        Org__c scratchOrg = [Select Id From Org__c Where Name =: 'Scratch Org Branch'];

        //Assign the dev hub id to the page as a parameter
        pageRef1.getParameters().put('id', scratchOrg.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller1 = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef2 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef2);

        //Select the correct scratch org
        Org__c scratchOrg1 = [Select Id From Org__c Where Name =: 'Scratch Org 1'];

        //Assign the dev hub id to the page as a parameter
        pageRef2.getParameters().put('id', scratchOrg1.Id);

        //Assign action name to the page as a parameter (lm = load metadata)
        pageRef2.getParameters().put('act', 'lm');

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller2 = new DXOperationController();

        //Check the org id
        system.assertEquals(scratchOrg1.Id,controller2.selectedOperationDataId);

        //Select manage manage definition template and execute function
        ApexPages.currentPage().getParameters().put('actionName', 'main');
        controller2.enableSelectedPanels();
    }

    @isTest static void existingUserStoryIdOperations() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        //Select the user story from lookup and populate actions. It will return because us do not belong to project and deployment flow is null
        User_Story__c uStory = [Select Id, User_Story_Title__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation'];

        //Assign the user story id to the page as a parameter
        pageRef.getParameters().put('id', uStory.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller = new DXOperationController();

        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef1 = Page.DXOperation;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef1);

        //Select the user story from lookup and populate actions.
        User_Story__c uStory1 = [Select Id, User_Story_Title__c From User_Story__c Where User_Story_Title__c =: 'Error on dx operation 2'];

        //Assign the user story id to the page as a parameter
        pageRef1.getParameters().put('id', uStory1.Id);

        //Instantiate and construct the controller class of DX Operation page.
        DXOperationController controller1 = new DXOperationController();

        //Check the us id
        system.assertEquals(uStory1.Id,controller1.usId);
    }
}