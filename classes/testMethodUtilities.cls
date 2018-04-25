public with sharing class testMethodUtilities {
    public static Deployment__c create(String name, DateTime dt1, DateTime dt2, Id fromOrgId, String schedule, String status){
        Deployment__c x = new Deployment__c();
        x.name = name;
        x.Date__c = dt1;
        x.Deployment_command_sent__c = dt2;
        x.From_Org__c = fromOrgId;
        x.Schedule__c = schedule;
        x.Status__c = status;
        return x;
    }
    public static Deployment_Job__c create(Integer numDeployed, Id destOrgId, String extId, String status, Id stepId){
        Deployment_Job__c x = new Deployment_Job__c();
        x.Deployed__c = numDeployed;
        x.Destination_Org__c = destOrgId;
        x.External_Id__c = extId;
        x.Status__c = status;
        x.Step__c = stepId;
        return x;
    }
    public static Step__c create(String name, String attId, String djson, Id deploymentId, Integer numOrder, String status, String stype){
        Step__c x = new Step__c();
        x.name = name;
        x.Attachment_Id__c = attId;
        x.dataJson__c = djson;
        x.Deployment__c = deploymentId;
        x.Order__c = numOrder;
        x.Status__c = status;
        x.Type__c = stype;
        return x;
    }
    public static Destination_Org__c create(Id deploymentId, String status, Id toOrgId){
        Destination_Org__c x = new Destination_Org__c();
        x.Deployment__c = deploymentId;
        x.Status__c = status;
        x.To_Org__c = toOrgId;
        return x;
    }
    public static Org__c create(String name, String orgType, String pw, String sfdcorgid, String token, String un, DateTime vd){
        Org__c x = new Org__c();
        x.name = name;
        x.Org_Type__c = orgType;
        x.password__c = pw;
        x.SFDC_Org_ID__c = sfdcorgid;
        x.Token__c = token;
        x.Username__c = un;
        x.Validated_Date__c = vd;
        return x;
    }
    public static Git_Repository__c create(String name, String un, String pw, String uri){
    	Git_Repository__c x = new Git_Repository__c();
    	x.Name = name;
    	x.Username__c = un;
    	x.Password__c = pw;
    	x.URI__c = uri;
    	return x;
    }
    public static Git_Backup__c create(String s, String b, String f, Git_Repository__c gr, Date lb, Org__c o){
    	Git_Backup__c x = new Git_Backup__c();
    	x.name = s;
    	x.Branch__c = b;
    	x.Frequency__c = f;
    	x.Git_Repository__c = gr.id;
    	x.Last_Backup__c = lb;
    	x.Org__c = o.id;
    	return x;
    }
    public static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
    public static OrgDiff__c createOrgDiff(String n, Org__c o1, Org__c o2, String f, String lmbn, Date since, Date til){
    	OrgDiff__c x = new OrgDiff__c();
    	x.name = n;
    	x.from_Org__c = o1.id;
    	x.to_Org__c = o2.id;
    	x.Last_Modified_By_Name__c = lmbn;
    	x.from_Date__c = since;
        x.to_Date__c = til;
    	x.Metadata_Types__c = f;
    	return x;
    }
    public static boolean hasMessage(String s){
        boolean b = false;
        for(ApexPages.Message msg : ApexPages.getMessages()){
            system.debug(msg);
            if(msg.getDetail().contains(s)) b = true;
        }
        return b;
    }
    public static void enableSelenium(){
        Settings__c s = Settings__c.getOrgDefaults();
        if(!s.Enabled_Multi_Licenses__c){
        	s.Enabled_Multi_Licenses__c = true;
	        upsert s;    
        }
        Copado_License__c lics = Copado_License__c.getInstance();
        if(!lics.Enable_CST__c){
         	lics.Enable_CST__c = true;
	        upsert lics;   
        }
         // "simulate" an API Key, since testmethods do not support webservice callouts inside DeployAPI.createAPIKey();
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if(String.isBlank(ps.API_Key__c)){
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }
    }

    public static String getTestNameSpace(){
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1)
            return 'copado__';
        return 'none';
    }

    public static Settings__c upsertOrgwideSettings(){
        Settings__c s = new Settings__c(Namespace__c = testMethodUtilities.getTestNameSpace(), server_url__c = 'test.com');
        Blob key = Crypto.generateAesKey(256);
        s.cryptoKey__c = EncodingUtil.base64Encode(key);
        Utilities.Secure_DML(s, Utilities.DML_Action.UPS, schema.Sobjecttype.Settings__c);

        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if(String.isBlank(ps.API_Key__c)){
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        return s;
    }
}