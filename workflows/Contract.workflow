<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update5</fullName>
        <field>ShippingGeocodeAccuracy</field>
        <name>Update5</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update1</fullName>
        <field>ActivatedDate</field>
        <name>update1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update2</fullName>
        <field>BillingCountry</field>
        <name>update2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update3</fullName>
        <field>BillingGeocodeAccuracy</field>
        <name>update3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update4</fullName>
        <field>StartDate</field>
        <name>update4</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update6</fullName>
        <field>ShippingLongitude</field>
        <name>update6</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update7</fullName>
        <field>SpecialTerms</field>
        <name>update7</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update8</fullName>
        <field>Status</field>
        <name>update8</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update9</fullName>
        <field>OwnerExpirationNotice</field>
        <name>update9</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>contract</fullName>
        <actions>
            <name>Update5</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update3</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update4</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update6</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update7</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update8</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>update9</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.BillingCity</field>
            <operation>contains</operation>
            <value>test</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
