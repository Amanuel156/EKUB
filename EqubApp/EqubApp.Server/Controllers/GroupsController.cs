using EqubApp.Server.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace EqubApp.Server.Controllers;

[ApiController]
[Route("api/groups")]
public class GroupsController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public GroupsController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    // CREATE GROUP
    [HttpPost("create")]
    public IActionResult CreateGroup([FromBody] CreateGroupRequest request)
    {
        try
        {
            using var conn =
                new SqlConnection(_configuration.GetConnectionString("EqubDb"));

            conn.Open();

            string sql = @"
                INSERT INTO app.Groups
                (
                    GroupName,
                    Description,
                    ContributionAmount,
                    CurrencyCode,
                    FrequencyTypeId,
                    MaxMembers,
                    CreatedByUserId,
                    GroupStatusId,
                    StartDate,
                    IsPayoutOrderLocked,
                    CreatedAtUtc
                )
                VALUES
                (
                    @GroupName,
                    @Description,
                    @ContributionAmount,
                    'USD',
                    1,
                    @MaxMembers,
                    @CreatedByUserId,
                    1,
                    GETDATE(),
                    0,
                    GETUTCDATE()
                );

                SELECT SCOPE_IDENTITY();
            ";

            using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.AddWithValue(
                "@GroupName",
                request.GroupName
            );

            cmd.Parameters.AddWithValue(
                "@Description",
                request.Description ?? ""
            );

            cmd.Parameters.AddWithValue(
                "@ContributionAmount",
                request.ContributionAmount
            );

            cmd.Parameters.AddWithValue(
                "@MaxMembers",
                request.MaxMembers
            );

            cmd.Parameters.AddWithValue(
                "@CreatedByUserId",
                request.CreatedByUserId
            );

            var groupId = Convert.ToInt32(cmd.ExecuteScalar());

            // Automatically add creator as ADMIN member
            string memberSql = @"
                INSERT INTO app.GroupMembers
                (
                    GroupId,
                    UserId,
                    MemberStatusId,
                    JoinedAtUtc
                )
                VALUES
                (
                    @GroupId,
                    @UserId,
                    1,
                    GETUTCDATE()
                )
            ";

            using var memberCmd = new SqlCommand(memberSql, conn);

            memberCmd.Parameters.AddWithValue(
                "@GroupId",
                groupId
            );

            memberCmd.Parameters.AddWithValue(
                "@UserId",
                request.CreatedByUserId
            );

            memberCmd.ExecuteNonQuery();

            return Ok(new
            {
                success = true,
                message = "Group created successfully",
                groupId = groupId
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    // ONLY SHOW USER'S GROUPS
    [HttpGet("my-groups/{userId}")]
    public IActionResult GetMyGroups(long userId)
    {
        try
        {
            var groups = new List<object>();

            using var conn =
                new SqlConnection(_configuration.GetConnectionString("EqubDb"));

            conn.Open();

            string sql = @"
                SELECT DISTINCT
                    g.GroupId,
                    g.GroupName,
                    g.Description,
                    g.ContributionAmount,
                    g.CurrencyCode,
                    g.MaxMembers,
                    g.StartDate,
                    g.IsPayoutOrderLocked,
                    gs.StatusName,
                    ft.FrequencyName,
                    g.CreatedAtUtc,
                    CASE
                        WHEN g.CreatedByUserId = @UserId
                        THEN 1
                        ELSE 0
                    END AS IsAdmin
                FROM app.Groups g
                LEFT JOIN app.GroupMembers gm
                    ON g.GroupId = gm.GroupId
                    AND gm.UserId = @UserId
                JOIN ref.GroupStatus gs
                    ON g.GroupStatusId = gs.GroupStatusId
                JOIN ref.FrequencyType ft
                    ON g.FrequencyTypeId = ft.FrequencyTypeId
                WHERE g.CreatedByUserId = @UserId
                   OR gm.UserId = @UserId
                ORDER BY g.GroupId DESC
            ";

            using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.AddWithValue(
                "@UserId",
                userId
            );

            using var reader = cmd.ExecuteReader();

            while (reader.Read())
            {
                groups.Add(new
                {
                    groupId = reader["GroupId"],
                    groupName = reader["GroupName"],
                    description = reader["Description"],
                    contributionAmount =
                        reader["ContributionAmount"],
                    currencyCode =
                        reader["CurrencyCode"],
                    maxMembers =
                        reader["MaxMembers"],
                    startDate =
                        reader["StartDate"],
                    isPayoutOrderLocked =
                        reader["IsPayoutOrderLocked"],
                    statusName =
                        reader["StatusName"],
                    frequencyName =
                        reader["FrequencyName"],
                    createdAtUtc =
                        reader["CreatedAtUtc"],
                    isAdmin =
                        Convert.ToBoolean(reader["IsAdmin"])
                });
            }

            return Ok(groups);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    // REMOVE USER FROM GROUP (ADMIN ONLY)
    [HttpDelete("{groupId}/remove-user/{userId}")]
    public IActionResult RemoveUser(
        int groupId,
        int userId
    )
    {
        try
        {
            using var conn =
                new SqlConnection(_configuration.GetConnectionString("EqubDb"));

            conn.Open();

            string sql = @"
                DELETE FROM app.GroupMembers
                WHERE GroupId = @GroupId
                AND UserId = @UserId
            ";

            using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.AddWithValue(
                "@GroupId",
                groupId
            );

            cmd.Parameters.AddWithValue(
                "@UserId",
                userId
            );

            cmd.ExecuteNonQuery();

            return Ok(new
            {
                success = true,
                message = "User removed from group"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                success = false,
                error = ex.Message
            });
        }
    }
}