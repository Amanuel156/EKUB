using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace EqubApp.Server.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public UsersController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet]
    public IActionResult GetUsers()
    {
        try
        {
            var users = new List<object>();

            using var conn = new SqlConnection(_configuration.GetConnectionString("EqubDb"));
            conn.Open();

            string sql = @"
                SELECT UserId, FirstName, LastName, Email
                FROM app.Users
                WHERE IsActive = 1
                ORDER BY UserId;
            ";

            using var cmd = new SqlCommand(sql, conn);
            using var reader = cmd.ExecuteReader();

            while (reader.Read())
            {
                users.Add(new
                {
                    userId = reader["UserId"],
                    firstName = reader["FirstName"],
                    lastName = reader["LastName"],
                    email = reader["Email"]
                });
            }

            return Ok(users);
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, error = ex.Message });
        }
    }
}