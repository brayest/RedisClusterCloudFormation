apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

package %w(r-base libhiredis-dev gdebi-core) do
  action :install
end

bash "Install R deps" do
  user "root"
  group "root"
  code <<-EOF
      R -e "install.packages(c('shiny','shinyjs','shinyBS','redux','DT'), repos='https://cran.rstudio.com/')"
  EOF
end


remote_file '/home/shiny-server-1.5.6.875-amd64.deb' do
  source 'https://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.5.6.875-amd64.deb'
  mode '0644'
  action :create
end

bash "reload daemon" do
  user "root"
  group "root"
  code <<-EOF
gdebi -n /home/shiny-server-1.5.6.875-amd64.deb
EOF
end

directory '/srv/shiny-server/app' do
  owner 'shiny'
  group 'shiny'
  mode '0755'
  action :create
end

file '/srv/shiny-server/app/app.R' do
  content 'library(shiny)
library(shinyjs)
library(shinyBS)
library(redux)
library(DT)

jsResetCode <- "shinyjs.reset = function() {history.go(0)}"

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(text = jsResetCode, functions = c("reset")),
  tableOutput("TABLE"),
  actionButton("refresh", "REFRESH")
)


server <- function(input, output) {
  INSTANCES <- c("10.1.1.10","10.1.2.10","10.1.3.10","10.1.4.10")
  ROLES <- vector(mode = "character", length = length(INSTANCES))

  for ( i in 1:length(INSTANCES) ) {
    res <- system(paste("echo exit | telnet",INSTANCES[i],"6379", sep = " "),intern = TRUE)
    if ( !is.na(res[2]) ) {
      r <- redux::hiredis(host = INSTANCES[i])
      info <- r$INFO("Replication")
      split <- strsplit(info, "\r\n")[[1]]
      ROLES[i] <- split[2]
    } else {
      ROLES[i] <- "INACTIVE"
    }
  }
  ROLE_TABLE <- data.frame(
    INITIAL_ROLE=c("MASTER","SLAVE_1", "SLAVE_2", "SLAVE_3"),
    IP_ADDRESS=INSTANCES,
    ACTUAL_ROLE=ROLES,
    stringsAsFactors = FALSE
  )
  output$TABLE <- renderTable({ROLE_TABLE},
                             striped = TRUE, bordered = TRUE,
                             hover = TRUE,
                             width = "100%")

  observeEvent(input$refresh, js$reset())
}

# Run the application
shinyApp(ui = ui, server = server)

'
end
