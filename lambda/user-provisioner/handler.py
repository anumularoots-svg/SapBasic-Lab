"""
User Provisioner — Creates student01..N in Simple AD via LDAP.
Invoke manually after directory is ready.
"""
import subprocess
import os
import json


def lambda_handler(event, context):
    directory_name = os.environ["DIRECTORY_NAME"]
    student_count = int(os.environ["STUDENT_COUNT"])
    password = os.environ["STUDENT_PWD"]
    dns_ips = os.environ["DNS_IPS"].split(",")

    # Build base DN from directory name (sap-lab.local → dc=sap-lab,dc=local)
    base_dn = ",".join([f"dc={p}" for p in directory_name.split(".")])
    ldap_uri = f"ldap://{dns_ips[0]}"

    created = []
    errors = []

    for i in range(1, student_count + 1):
        username = f"student{i:02d}"
        dn = f"cn={username},cn=Users,{base_dn}"

        ldif = f"""dn: {dn}
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: {username}
sAMAccountName: {username}
userPrincipalName: {username}@{directory_name}
givenName: Student
sn: {i:02d}
displayName: Student {i:02d}
userAccountControl: 512
unicodePwd: {encode_password(password)}
"""
        try:
            # Use ldapadd to create user
            result = subprocess.run(
                ["ldapadd", "-x", "-H", ldap_uri,
                 "-D", f"Administrator@{directory_name}",
                 "-w", os.environ.get("ADMIN_PWD", password)],
                input=ldif, capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                created.append(username)
            elif "Already exists" in result.stderr:
                created.append(f"{username} (exists)")
            else:
                errors.append(f"{username}: {result.stderr}")
        except Exception as e:
            errors.append(f"{username}: {str(e)}")

    return {"created": len(created), "errors": errors}


def encode_password(password):
    """Encode password for AD unicodePwd attribute."""
    return '"{}"'.format(password).encode("utf-16-le").hex()
