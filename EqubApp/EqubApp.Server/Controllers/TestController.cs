using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System;

namespace EqubApp.Server.Controllers;

[ApiController]
[Route("api/test")]
public class TestController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public TestController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet]
    public IActionResult TestConnection()
    {
        try
        {
            var connectionString =
                _configuration.GetConnectionString("EqubDb");

            using SqlConnection conn =
                new SqlConnection(connectionString);

            conn.Open();

            return Ok(new
            {
                success = true,
                message = "SQL Server Connected Successfully",
                server = conn.DataSource,
                database = conn.Database
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