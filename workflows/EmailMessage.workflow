<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_last_follow_up_email</fullName>
        <field>Last_Message_Date__c</field>
        <formula>LastModifiedDate</formula>
        <name>Update last follow up email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Last message</fullName>
        <actions>
            <name>Update_last_follow_up_email</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Incoming = FALSE</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
