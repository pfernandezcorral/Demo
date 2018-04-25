public with sharing class CMTestMethodUtilities {
	public static Project__c createProject(String s){
		Project__c x = new Project__c();
		x.Name = s;
		return x;
	}
	public static Sprint__c createSprint(String s){
		Sprint__c x = new Sprint__c();
		x.Name = s;
		return x;
	}
	public static User_Story__c createUserStory(String s){
		User_Story__c x = new User_Story__c();
		x.User_Story_Title__c = s;
		return x;
	}
	public static Test_Script__c createTestScript(String title){
		Test_Script__c x = new Test_Script__c();
		x.Test_Title__c = title;
		return x;
	}
	public static Test_Script_Step__c createTestScriptStep(Id scriptId, String title){
		Test_Script_Step__c x = new Test_Script_Step__c();
		x.Test_Script__c = scriptId;
		x.Step_Title__c = title;
		return x;
	}
	public static Test_Run__c createTestRun(Id scriptId){
		Test_Run__c x = new Test_Run__c();
		x.Test_Script__c = scriptId;
		return x;	
	}
	public static Test_Run_Step__c createTestRunStep(Id runId, Id stepId){
		Test_Run_Step__c x = new Test_Run_Step__c();
		x.Test_Run__c = runId;
		x.Script_Step__c = stepId;
		return x;	
	}
	public static Release__c createRelease(String s){
		Release__c x = new Release__c();
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createFlow(String s){
		Deployment_Flow__c x = new Deployment_Flow__c();
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createCCMFlow(String s, Boolean a){
		Deployment_Flow__c x = new Deployment_Flow__c();
        x.Active__c = a;
		x.Name = s;
		return x;
	}
    public static Deployment_Flow__c createCBMFlow(String s, Boolean a, Id repoId, String b){
		Deployment_Flow__c x = new Deployment_Flow__c();
        x.Active__c = a;
        x.Git_Repository__c = repoId;
        x.Main_Branch__c = b;
		x.Name = s;
		return x;
	}
	public static Deployment_Flow_Step__c createFlowStep(Id sourceEnvId, Id destEnvId, Id flowId){
		Deployment_Flow_Step__c x = new Deployment_Flow_Step__c();
        x.Source_Environment__c = sourceEnvId;
        x.Destination_Environment__c = destEnvId;
		x.Deployment_Flow__c = flowId;
		return x;
	}
	public static Promotion__c createPromotion(Id projectId, Id sourceEnvId){
		Promotion__c x = new Promotion__c();
		x.Project__c = projectId;
        x.Source_Environment__c = sourceEnvId;
		return x;
	}
	public static Promotion__c createBackPromotion(Id projectId, Id destinationEnvId){
		Promotion__c x = new Promotion__c();
		x.Project__c = projectId;
        x.Destination_Environment__c = destinationEnvId;
        x.Back_Promotion__c = true;
		return x;
	}
    public static Environment__c createEnvironment(String name, String orgId){
        Environment__c x = new Environment__c();
        x.Name = name;
        x.org_id__c = orgId;
        return x;
    }
	public static boolean hasMessage(String s){
        boolean b = false;
        for(ApexPages.Message msg : ApexPages.getMessages()){
            if(msg.getDetail().contains(s)) b = true;
        }
        return b;
    }
    public static Org__c createOrg(String name, String orgType, String pw, String sfdcorgid, String token, String un, DateTime vd, Id envId){
        Org__c x = new Org__c();
        x.name = name;
        x.Org_Type__c = orgType;
        x.password__c = pw;
        x.SFDC_Org_ID__c = sfdcorgid;
        x.Token__c = token;
        x.Username__c = un;
        x.Validated_Date__c = vd;
        x.Environment__c = envId;
        return x;
    }
    public static void enableSelenium(){
        try{
            testMethodUtilities.enableSelenium();
        }catch(DMLexception e) {
            System.debug('Avoid UNABLE_TO_LOCK_ROW exceptions, due to concurrent updates to custom settings');
        }
    }
    public static void addNamespaceSetting(String value) {
    	List<Settings__c> settings = [SELECT Namespace__c FROM Settings__c Where Namespace__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Namespace__c != value) {
					s.Namespace__c = value;
					Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
				}
			}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Namespace__c = value), Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
    	}
    }
    public static void addServerURLSetting(String value) {
    	List<Settings__c> settings = [SELECT Server_URL__c FROM Settings__c Where Server_URL__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Server_URL__c != value) {
	    			s.Server_Url__c = value;
	    			Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
	    		}
	    	}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Server_URL__c = value), Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);
    	}
    }
    public static void enabledMultiLicenses(Boolean value) {
    	List<Settings__c> settings = [SELECT Enabled_Multi_Licenses__c FROM Settings__c Where Enabled_Multi_Licenses__c != null Limit 1 FOR UPDATE];
    	if(settings.size() > 0) {
    		for(Settings__c s : settings) {
	    		if(s.Enabled_Multi_Licenses__c != value) {
	    			s.Enabled_Multi_Licenses__c = value;
	    			Utilities.Secure_DML(s, Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
	    		}
	    	}
    	} else {
    		Utilities.Secure_DML(new Settings__c(Enabled_Multi_Licenses__c = value), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
    	}
    }
}