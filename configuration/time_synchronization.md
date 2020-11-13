# Active Directory

## Time Synchronization

The time configuration is determined by the Time32 windows service.
According use case, your time toplogy will be different but based on the same principe of trusted source.

The top level domain use a trusted NTP server to sync time.
Each sub domain DC's sync time with root domain.

In every case, each member servers needs to sync time with DC's of his own domain to ensure reliability.

### Mono domain/Mono Forest

```mermaid
graph TD;
    NTP[NTP Server] -->|Sync with private or public NTP| ForestDomain{Root domain}
    ForestDomain -->|Sync with member servers|MemberRoot1[Server A]
    ForestDomain -->MemberRoot2[Server B]
```

### Forest and childs domains

```mermaid
graph TD;
    NTP[fa:fa-history NTP Server] -->|Sync with private or public NTP| ForestDomain{Forest root domain}
    ForestDomain --> ChildA{Child domain A}
    ForestDomain --> ChildB{Child domain B}
    ChildA -->|Sync with member servers| MemberA1[fa:fa-server Server C]
    ChildA --> MemberA2[fa:fa-server Server D]
    ChildB -->|Sync with member servers| MemberB1[fa:fa-server Server E]
    ChildB --> MemberB2[fa:fa-server Server F]
    ForestDomain -->|Sync with member servers|MemberRoot1[fa:fa-server Server A]
    ForestDomain -->MemberRoot2[fa:fa-server Server B]
```

## Sources

- [https://social.technet.microsoft.com/wiki/contents/articles/50924.active-directory-time-synchronization.aspx](https://social.technet.microsoft.com/wiki/contents/articles/50924.active-directory-time-synchronization.aspx)
- [https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/how-the-windows-time-service-works](https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/how-the-windows-time-service-works)