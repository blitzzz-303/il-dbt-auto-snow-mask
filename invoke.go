
package main
import (
        "fmt"
        "log"
        "net/http"
        "net/http/httputil"
        "os"
        "os/exec"
)
func handler(w http.ResponseWriter, r *http.Request) {
        log.Print("-- received an apply")
        cmd := exec.Command("/bin/sh", "script.sh")
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        err := cmd.Run()
        if err != nil {
        log.Fatalf("cmd.Run() failed with %s\n", err)
        }
}
func handler_scan(w http.ResponseWriter, r *http.Request) {
        log.Print("-- received a scan")
        cmd := exec.Command("/bin/sh", "script_scan.sh")
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        err := cmd.Run()
        if err != nil {
        log.Fatalf("cmd.Run() failed with %s\n", err)
        }
}
func handler_unapply(w http.ResponseWriter, r *http.Request) {
        log.Print("-- received an unapply")
        cmd := exec.Command("/bin/sh", "script_unapply.sh")
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        err := cmd.Run()
        if err != nil {
        log.Fatalf("cmd.Run() failed with %s\n", err)
        }
}
func indexHandler(w http.ResponseWriter, r *http.Request) {
        reqDump, err := httputil.DumpRequest(r, true)
        if err != nil {
            log.Fatal(err)
        }
    
        fmt.Printf("REQUEST:\n%s", string(reqDump))
}
func main() {
        log.Print("-- starting server...")
        http.HandleFunc("/", indexHandler)
        http.HandleFunc("/apply", handler)
        http.HandleFunc("/scan", handler_scan)
        http.HandleFunc("/unapply", handler_unapply)
        port := os.Getenv("PORT")
        if port == "" {
                port = "8080"
        }
        log.Printf("-- listening on %s", port)
        log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}