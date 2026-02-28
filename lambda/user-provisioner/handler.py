import os
import json
import ldap3

def lambda_handler(event, context):
    directory_name = os.environ["DIRECTORY_NAME"]
    student_count = int(os.environ["STUDENT_COUNT"])
    password = os.environ["STUDENT_PWD"]
    dns_ips = os.environ["DNS_IPS"].split(",")

    # Build base DN: sap-lab.local → dc=sap-lab,dc=local
    base_dn = ",".join([f"dc={p}" for p in directory_name.split(".")])
    admin_dn = f"Administrator@{directory_name}"
    admin_pwd = os.environ.get("ADMIN_PWD", password)

    server = ldap3.Server(dns_ips[0], port=389, use_ssl=False)
    conn = ldap3.Connection(server, user=admin_dn, password=admin_pwd, auto_bind=True)

    created = []
    errors = []

    for i in range(1, student_count + 1):
        username = f"student{i:02d}"
        user_dn = f"cn={username},cn=Users,{base_dn}"

        attrs = {
            "objectClass": ["top", "person", "organizationalPerson", "user"],
            "sAMAccountName": username,
            "userPrincipalName": f"{username}@{directory_name}",
            "givenName": "Student",
            "sn": f"{i:02d}",
            "displayName": f"Student {i:02d}",
            "userAccountControl": "544",
        }

        try:
            result = conn.add(user_dn, attributes=attrs)
            if result:
                # Set password
                encoded_pwd = f'"{password}"'.encode("utf-16-le")
                conn.modify(user_dn, {"unicodePwd": [(ldap3.MODIFY_REPLACE, [encoded_pwd])]})
                # Enable account
                conn.modify(user_dn, {"userAccountControl": [(ldap3.MODIFY_REPLACE, ["512"])]})
                created.append(username)
            elif "entryAlreadyExists" in str(conn.result):
                created.append(f"{username} (exists)")
            else:
                errors.append(f"{username}: {conn.result}")
        except Exception as e:
            if "entryAlreadyExists" in str(e):
                created.append(f"{username} (exists)")
            else:
                errors.append(f"{username}: {str(e)}")

    conn.unbind()
    return {"created": len(created), "users": created, "errors": errors}
