"""
GuardDuty 이벤트 기반 IP 자동 차단 Lambda 함수

GuardDuty가 탐지한 위협의 소스 IP를 WAF IP Set에 자동으로 추가하여 차단합니다.
"""
import json
import os
import boto3
import urllib3
from typing import Dict, List, Any

# AWS 클라이언트 초기화
wafv2 = boto3.client('wafv2')
sns = boto3.client('sns')
http = urllib3.PoolManager()

# 환경 변수
WAF_IP_SET_ID = os.environ.get('WAF_IP_SET_ID')
WAF_IP_SET_ARN = os.environ.get('WAF_IP_SET_ARN')
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')

# ARN에서 Scope와 IP Set ID 추출
def parse_waf_arn(arn: str) -> Dict[str, str]:
    """WAF ARN에서 Scope와 ID를 추출"""
    # 예: arn:aws:wafv2:ap-northeast-2:123456789012:regional/ipset/name/id
    parts = arn.split('/')
    scope_part = parts[0].split(':')[-1]  # 'regional' or 'cloudfront'
    ip_set_id = parts[-1]
    ip_set_name = parts[-2]
    
    scope = 'REGIONAL' if scope_part == 'regional' else 'CLOUDFRONT'
    
    return {
        'scope': scope,
        'id': ip_set_id,
        'name': ip_set_name
    }


def extract_ip_from_finding(finding: Dict[str, Any]) -> List[str]:
    """
    GuardDuty Finding에서 공격자 IP 주소 추출
    
    Args:
        finding: GuardDuty Finding JSON 객체
        
    Returns:
        추출된 IP 주소 리스트
    """
    ips = []
    
    # Resource 필드에서 IP 추출
    resource = finding.get('resource', {})
    
    # Instance Details에서 IP 추출
    if 'instanceDetails' in resource:
        instance_details = resource['instanceDetails']
        if 'networkInterfaces' in instance_details:
            for interface in instance_details['networkInterfaces']:
                if 'privateIpAddresses' in interface:
                    for private_ip in interface['privateIpAddresses']:
                        if 'privateIpAddress' in private_ip:
                            ips.append(private_ip['privateIpAddress'])
                if 'publicIp' in interface:
                    ips.append(interface['publicIp'])
    
    # Service 필드에서 IP 추출 (Remote IP)
    service = finding.get('service', {})
    if 'action' in service:
        action = service['action']
        if 'networkConnectionAction' in action:
            network_action = action['networkConnectionAction']
            if 'remoteIpDetails' in network_action:
                remote_ip = network_action['remoteIpDetails']
                if 'ipAddressV4' in remote_ip:
                    ips.append(remote_ip['ipAddressV4'])
        
        # DNS Action에서 IP 추출
        if 'dnsRequestAction' in action:
            dns_action = action['dnsRequestAction']
            if 'remoteIpDetails' in dns_action:
                remote_ip = dns_action['remoteIpDetails']
                if 'ipAddressV4' in remote_ip:
                    ips.append(remote_ip['ipAddressV4'])
    
    # 중복 제거 및 None 값 제거
    ips = list(set([ip for ip in ips if ip and ip.strip()]))
    
    return ips


def get_current_ip_set() -> Dict[str, Any]:
    """현재 WAF IP Set 조회"""
    waf_info = parse_waf_arn(WAF_IP_SET_ARN)
    
    response = wafv2.get_ip_set(
        Scope=waf_info['scope'],
        Id=waf_info['id'],
        Name=waf_info['name']
    )
    
    return response


def update_ip_set(new_ips: List[str]) -> bool:
    """
    WAF IP Set에 새 IP 주소 추가
    
    Args:
        new_ips: 추가할 IP 주소 리스트
        
    Returns:
        성공 여부
    """
    try:
        waf_info = parse_waf_arn(WAF_IP_SET_ARN)
        
        # 현재 IP Set 조회
        current_set = get_current_ip_set()
        current_addresses = set(current_set['IPSet']['Addresses'])
        
        # 새 IP 추가 (CIDR 형식 변환)
        updated_addresses = current_addresses.copy()
        for ip in new_ips:
            # IPv4 주소를 /32 CIDR로 변환
            if '/' not in ip:
                ip = f"{ip}/32"
            updated_addresses.add(ip)
        
        # IP Set 업데이트
        wafv2.update_ip_set(
            Scope=waf_info['scope'],
            Id=waf_info['id'],
            Name=waf_info['name'],
            Description=current_set['IPSet'].get('Description', ''),
            Addresses=list(updated_addresses),
            LockToken=current_set['LockToken']
        )
        
        return True
    except Exception as e:
        print(f"Error updating IP set: {str(e)}")
        return False


def send_slack_notification(finding: Dict[str, Any], blocked_ips: List[str]) -> None:
    """Slack으로 차단 알림 전송"""
    if not SLACK_WEBHOOK_URL:
        return
    
    severity = finding.get('severity', 'N/A')
    title = finding.get('title', 'Unknown Threat')
    finding_type = finding.get('type', 'Unknown')
    account_id = finding.get('accountId', 'N/A')
    region = finding.get('region', 'N/A')
    
    message = {
        "text": "🚨 GuardDuty 위협 탐지 및 자동 차단",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🚨 GuardDuty 위협 탐지 및 자동 차단"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Finding Type:*\n{finding_type}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Severity:*\n{severity}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Account ID:*\n{account_id}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Region:*\n{region}"
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Title:*\n{title}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*차단된 IP 주소:*\n```\n" + "\n".join(blocked_ips) + "\n```"
                }
            }
        ]
    }
    
    try:
        response = http.request(
            'POST',
            SLACK_WEBHOOK_URL,
            body=json.dumps(message).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        print(f"Slack notification sent: {response.status}")
    except Exception as e:
        print(f"Error sending Slack notification: {str(e)}")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda 함수 핸들러
    
    EventBridge에서 GuardDuty Finding을 수신하여 IP 차단 처리
    """
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # EventBridge 이벤트 형식에서 GuardDuty Finding 추출
        detail = event.get('detail', {})
        
        # GuardDuty Finding에서 IP 추출
        blocked_ips = extract_ip_from_finding(detail)
        
        if not blocked_ips:
            print("No IP addresses found in the finding")
            return {
                'statusCode': 200,
                'body': json.dumps('No IP addresses to block')
            }
        
        print(f"Extracted IPs to block: {blocked_ips}")
        
        # WAF IP Set 업데이트
        success = update_ip_set(blocked_ips)
        
        if success:
            print(f"Successfully blocked IPs: {blocked_ips}")
            
            # 알림 전송 (SNS 및 Slack)
            send_sns_notification(detail, blocked_ips)
            send_slack_notification(detail, blocked_ips)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'IPs successfully blocked',
                    'blocked_ips': blocked_ips
                })
            }
        else:
            return {
                'statusCode': 500,
                'body': json.dumps('Failed to update IP set')
            }
            
    except Exception as e:
        print(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

