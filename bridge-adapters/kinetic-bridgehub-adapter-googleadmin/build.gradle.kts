import java.text.SimpleDateFormat
import java.util.Date

plugins {
    java
    `maven-publish`
    id("net.nemerosa.versioning") version "2.14.0"
}

repositories {
  mavenLocal()
  maven {
    url = uri("https://s3.amazonaws.com/maven-repo-public-kineticdata.com/releases")
  }

  maven {
    url = uri("s3://maven-repo-private-kineticdata.com/releases")
    authentication {
      create<AwsImAuthentication>("awsIm")
    }

  }

  maven {
    url = uri("https://s3.amazonaws.com/maven-repo-public-kineticdata.com/snapshots")
  }

  maven {
    url = uri("s3://maven-repo-private-kineticdata.com/snapshots")
    authentication {
      create<AwsImAuthentication>("awsIm")
    }
  }

  maven {
    url = uri("https://repo.maven.apache.org/maven2/")
  }

  maven {
    url = uri("https://repo.springsource.org/release/")
  }

}

dependencies {
    implementation("com.kineticdata.agent:kinetic-agent-adapter:1.1.3")
    implementation("com.google.api-client:google-api-client:1.35.0")
    implementation("com.google.api-client:google-api-client-jackson2:1.20.0")
    implementation("com.google.oauth-client:google-oauth-client-jetty:1.33.3")
    implementation("com.google.apis:google-api-services-admin-directory:directory_v1-rev63-1.21.0")
    implementation("org.slf4j:slf4j-api:1.7.10")
    implementation("com.google.guava:guava:19.0")
    testImplementation("junit:junit:4.13.1")
}

group = "com.kineticdata.bridges.adapter"
version = "1.1.2"
description = "kinetic-bridgehub-adapter-googleadmin"
java.sourceCompatibility = JavaVersion.VERSION_1_8

publishing {
  repositories {
    maven {
      val releasesUrl = uri("s3://maven-repo-private-kineticdata.com/releases")
      val snapshotsUrl = uri("s3://maven-repo-private-kineticdata.com/snapshots")
      url = if (version.toString().endsWith("SNAPSHOT")) snapshotsUrl else releasesUrl
      authentication {
        create<AwsImAuthentication>("awsIm")
      }
    }
  }
    publications.create<MavenPublication>("maven") {
        from(components["java"])
    }
}

tasks.withType<JavaCompile>() {
    options.encoding = "UTF-8"
}
versioning {
  gitRepoRootDir = "../../"
}
tasks.processResources {
  duplicatesStrategy = DuplicatesStrategy.INCLUDE
  val currentDate = SimpleDateFormat("yyyy-MM-dd").format(Date())
  from("src/main/resources"){
    filesMatching("**/*.version") {    
      expand(    
        "buildNumber" to versioning.info.build,
        "buildDate" to currentDate,    
        "timestamp" to System.currentTimeMillis(),    
        "version" to project.version    
      )    
    }
  }
}
