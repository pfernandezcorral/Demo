@isTest
private class TestSprintVirtualWall {
	
    public static String getTestNameSpace(){
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1)
            return 'copado__';
        return 'none';
    }
    public static Settings__c getTestSettings(){
        Settings__c s = new Settings__c(Namespace__c = getTestNameSpace(), server_url__c = 'test.com', Enabled_Multi_Licenses__c=false);
        return s;
    }

	@isTest static void test_constructor_1_reOrderSame() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(-8);
		s.End_Date__c = date.today().addDays(8);
		insert s;

		Sprint__c nextS = new Sprint__c();
		nextS.Start_Date__c = date.today().addDays(20);
		nextS.End_Date__c = date.today().addDays(28);
		insert nextS;	

		Sprint__c prevS = new Sprint__c();
		prevS.Start_Date__c = date.today().addDays(-28);
		prevS.End_Date__c = date.today().addDays(-20);
		insert prevS;		

		User_Story__c us = new User_Story__c();
		us.Sprint__c = s.Id;
		us.Story_Points_SFDC__c = 5;
		us.Order__c = 0;
		insert us;

		User_Story__c usCompleted = new User_Story__c();
		usCompleted.Sprint__c = s.Id;
		usCompleted.Story_Points_SFDC__c = 5;
		usCompleted.Order__c = 0; // THIS will Change
		insert usCompleted;		

		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);

		//Order had to be given
		system.assertEquals(0, SVW.sw.userStories[0].theUS.Order__c);
		system.assertEquals(1, SVW.sw.userStories[1].theUS.Order__c);
	}
@isTest static void test_constructor_1_reOrderNotNext() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(-8);
		s.End_Date__c = date.today().addDays(8);
		insert s;

		Sprint__c nextS = new Sprint__c();
		nextS.Start_Date__c = date.today().addDays(20);
		nextS.End_Date__c = date.today().addDays(28);
		insert nextS;	

		Sprint__c prevS = new Sprint__c();
		prevS.Start_Date__c = date.today().addDays(-28);
		prevS.End_Date__c = date.today().addDays(-20);
		insert prevS;		

		User_Story__c us = new User_Story__c();
		us.Sprint__c = s.Id;
		us.Story_Points_SFDC__c = 5;
		us.Order__c = 0;
		insert us;

		User_Story__c usCompleted = new User_Story__c();
		usCompleted.Sprint__c = s.Id;
		usCompleted.Story_Points_SFDC__c = 5;
		usCompleted.Order__c = 3; // THIS will Change
		insert usCompleted;		

		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);

		//Order had to be given
		system.assertEquals(0, SVW.sw.userStories[0].theUS.Order__c);
		system.assertEquals(1, SVW.sw.userStories[1].theUS.Order__c);
	}
	@isTest static void test_constructor_1_SprintClosed() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(-18);
		s.End_Date__c = date.today().addDays(-8);
		insert s;

		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);

		//Order had to be given
		system.assertEquals(system.label.SprintWall_DaysLeft_Closed, SVW.daysLeft);
	}
	@isTest static void test_constructor_1_SprintNotStarted() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(8);
		s.End_Date__c = date.today().addDays(18);
		insert s;

		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);
		system.assertEquals(system.label.SprintWall_DaysLeft_Not_Started, SVW.daysLeft);
	}
	@isTest static void test_No_US_CreateFirst() {
		Settings__c sett = getTestSettings();
		insert sett;
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(8);
		s.End_Date__c = date.today().addDays(18);
		insert s;
		test.starttest();
		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);		
		//Create New User Story of RecordType Bug
		SVW.usRtId = SVW.rtWithId.get('Bug');
		SVW.newUserStory();
		test.stoptest();
		User_Story__c us = [select id, RecordTypeId from User_Story__c where Sprint__c =: s.Id];
		system.assertEquals(us.RecordTypeId, SVW.usRtId);
	}
	@isTest static void test_No_US_NoRT_Error() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(8);
		s.End_Date__c = date.today().addDays(18);
		insert s;
		test.starttest();
		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);
		//Create New User Story without setting RT
		try{
			SVW.newUserStory();			
		}catch(exception e){
			system.assert(e.getMessage().contains('INVALID_CROSS_REFERENCE_KEY'));
		}

		test.stoptest();
	}
	@isTest static void test_constructor_1_No_Order() {
		//Sprint To Use
		Sprint__c s = new Sprint__c();
		s.Start_Date__c = date.today().addDays(-8);
		s.End_Date__c = date.today().addDays(8);
		insert s;

		Sprint__c nextS = new Sprint__c();
		nextS.Start_Date__c = date.today().addDays(20);
		nextS.End_Date__c = date.today().addDays(28);
		insert nextS;	

		Sprint__c prevS = new Sprint__c();
		prevS.Start_Date__c = date.today().addDays(-28);
		prevS.End_Date__c = date.today().addDays(-20);
		insert prevS;		

		User_Story__c us = new User_Story__c();
		us.Sprint__c = s.Id;
		us.Story_Points_SFDC__c = 5;
		insert us;

		User_Story__c usCompleted = new User_Story__c();
		usCompleted.Sprint__c = s.Id;
		usCompleted.Story_Points_SFDC__c = 5;
		usCompleted.Status__c = system.label.SprintWall_Task_Status_Completed;
		insert usCompleted;		

		User_Story__c usThird = new User_Story__c();
		usThird.Sprint__c = s.Id;
		usThird.Story_Points_SFDC__c = 5;
		usThird.Status__c = system.label.SprintWall_Task_Status_Completed;
		insert usThird;	

		User_Story_Task__c t = new User_Story_Task__c();
		t.User_Story__c = us.Id;
		insert t;

		User_Story_Task__c tCompleted = new User_Story_Task__c();
		tCompleted.User_Story__c = us.Id;
		tCompleted.Status__c = system.label.SprintWall_Task_Status_Completed;
		insert tCompleted;

		ApexPages.StandardController sc = new ApexPages.StandardController(s);
		SprintVirtualWall SVW = new SprintVirtualWall(sc);

		//Order had to be given
		system.assertEquals(0, SVW.sw.userStories[0].theUS.Order__c);
		system.assertEquals(15, SVW.plannedVelocity);
		system.assertEquals(10, SVW.actualVelocity);

		//Create New User Story of RecordType Bug
		SVW.usRtId = SVW.rtWithId.get('Bug');
		SVW.newUserStory();
		system.assertEquals(3, SVW.sw.userStories.size()); //Because page will rerender and construsctor gets the new one

		//Move to Next Sprint
		SVW.actionIndex = '0';
		SVW.MoveToNextSprint();

		//Remove From Current Sprint
		SVW.removeFromCurrenSprint();
		system.assertEquals(3, SVW.sw.userStories.size()); // In the wrapper they are still there but have removed == true

		//Mass Update
		SVW.massUpdateUS.Status__c = system.label.SprintWall_Task_Status_In_Progress;
		SVW.sw.userStories[0].selected = true;
		SVW.massUpdateRecords();

		system.assertEquals(SVW.sw.userStories[0].theUS.Status__c, system.label.SprintWall_Task_Status_In_Progress);

		//dmlrow
		ApexPages.currentPage().getParameters().put('actionIndex','0');
		SVW.dmlRow();

		// dmlAll
		
		SVW.dmlALL();

		//TASK: Create NEW TASK
		
		SVW.createNewUSTask();

		//UPDATE THAT TASK
 			ApexPages.currentPage().getParameters().put('rIndex','0');
			ApexPages.currentPage().getParameters().put('beforeKey',system.label.SprintWall_Task_Status_Not_Started);
			ApexPages.currentPage().getParameters().put('afterKey', '');
			ApexPages.currentPage().getParameters().put('taskID', t.Id);
			ApexPages.currentPage().getParameters().put('tfield', 'Subject__c');
			ApexPages.currentPage().getParameters().put('tValue', 'Test Subject');
		SVW.updateTaskStatusApex();
		
		//UPDATE TASK TO NEXT COLUMN	
 			ApexPages.currentPage().getParameters().put('rIndex','0');
			ApexPages.currentPage().getParameters().put('beforeKey',system.label.SprintWall_Task_Status_Not_Started);
			ApexPages.currentPage().getParameters().put('afterKey', system.label.SprintWall_Task_Status_In_Progress);
			ApexPages.currentPage().getParameters().put('taskID', t.Id);
		SVW.updateTaskStatusApex();

		//Delete Task
 			ApexPages.currentPage().getParameters().put('rIndex','0');
			ApexPages.currentPage().getParameters().put('beforeKey',system.label.SprintWall_Task_Status_In_Progress);
			ApexPages.currentPage().getParameters().put('taskID', t.Id);

		SVW.deleteTask();

		//See If Chatter is enabled
		SprintVirtualWall.getisChatterEnabled();

	}
	
}