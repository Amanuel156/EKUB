namespace EqubApp.Server.Models;

public class CreateGroupRequest
{
    public string GroupName { get; set; } = "";
    public string? Description { get; set; }
    public long CreatedByUserId { get; set; } = 1;
    public decimal ContributionAmount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public byte FrequencyTypeId { get; set; } = 1;
    public int MaxMembers { get; set; }
    public DateTime StartDate { get; set; }
}

public class AddMemberRequest
{
    public long UserId { get; set; }
    public long AdminUserId { get; set; }
}

public class RemoveMemberRequest
{
    public long AdminUserId { get; set; }
}