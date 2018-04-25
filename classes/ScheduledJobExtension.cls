public with sharing class ScheduledJobExtension {
    public CronTrigger ct {get; set;}
    public Scheduled_Job__c job {get; set;}
    private ApexPages.StandardController cont;
    public Boolean showError {get; set;}
    public Boolean showOptions {get; set;}
    /**
     * To get all accessibleFields and add them to the Standard controller in order to avoid SOQL without querying exception
     * And also if someone adds a new field to the page they wont worry about adding the field to the controller.
     */
    public List<String> accessibleFields {
        get {
            if (accessibleFields == null) {
                // Get a list (map) of all fields on the object
                Map<String, Schema.SobjectField> fields = Schema.SobjectType.Scheduled_Job__c.fields.getMap();
                // Save only the fields accessible by the current user
                Set<String> availableFieldsSet = new Set<String>();
                for (String s : fields.keySet()) {
                    if (fields.get(s).getDescribe().isAccessible()
                    // Comment out next line to show standard/system fields.(bear in mind FLS of Std fields cannot be removed.)
                    && fields.get(s).getDescribe().isCustom()
                       ) {
                        availableFieldsSet.add(s.toLowerCase());
                    }
                }
                // Convert set to list, save to property. 
                // Even if in the current structure it is not possible, the Set is used to avoid duplicate fields exception just in case for the future enhancements.
                accessibleFields = new List<String>(availableFieldsSet);
            }
            return accessibleFields;
        }
        private set;
    }
    public ScheduledJobExtension(ApexPages.StandardController std) {
        if(!Test.isRunningTest()){
            std.addFields(accessibleFields);
        }else{
            List<String> fieldNames = new List<String>();
            fieldNames.addAll(accessibleFields);

        }
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        cont = std;
        job = (Scheduled_Job__c)std.getRecord();
        if (String.isnotBlank(job.Apex_Job_ID__c)) {
            List<CronTrigger> cts = [select Id, CronExpression , NextFireTime, PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey  from CronTrigger where Id = :job.Apex_Job_ID__c];
            ct = cts.size() > 0 ? cts.get(0) : null;
        }
        if (ct == null)ct = new CronTrigger();
    }

    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditScheduledJob')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }
    public PageReference stop() {
        if (String.isnotBlank(job.Apex_Job_ID__c)) {
            List<CronTrigger> cts = [select Id, CronExpression , NextFireTime, PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey  from CronTrigger where Id = :job.Apex_Job_ID__c];
            if (cts.size() > 0) {
                System.abortJob(job.Apex_Job_ID__c);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.JOB_UNSCHEDULED_SUCCESSFULLY ));
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, Label.NO_JOB_FOUND));
            }
            job.Apex_Job_ID__c = null;
            Utilities.Secure_DML(job, Utilities.DML_Action.UPD, schema.Sobjecttype.Scheduled_Job__c);
            ct = new CronTrigger();
            return null;
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, Label.NOTHING_TO_STOP));
        }
        return null;
    }
    public PageReference delete_job() {
        stop();
        Utilities.Secure_DML(job, Utilities.DML_Action.DEL, schema.Sobjecttype.Scheduled_Job__c);
        return cont.delete();
    }
    public PageReference schedule_job() {
        PageReference pr = Page.ScheduledJobSchedule;
        pr.getParameters().put('id', job.Id);
        return pr;
    }
    public PageReference save_job() {
        try {
            stop();
            String cron = job.Cron_Expression__c;
            String jobId = System.schedule(job.Name.left(80), cron, new WebhookSchedulable(job.Id));
            job.Apex_Job_ID__c  = jobId;
            Utilities.Secure_DML(job, Utilities.DML_Action.UPD, schema.Sobjecttype.Scheduled_Job__c);
            return new PageReference('/' + job.Id);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, Label.COULD_NOT_SCHEDULE_JOB + ': ' + e.getMessage()));
        }
        return null;
    }
}