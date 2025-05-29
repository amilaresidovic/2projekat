import { useState, useEffect } from "react";
import { createContact, updateContact } from "./api";

const ContactForm = ({ existingContact = {}, updateCallback }) => {
  const [firstName, setFirstName] = useState(existingContact.firstName || "");
  const [lastName, setLastName] = useState(existingContact.lastName || "");
  const [email, setEmail] = useState(existingContact.email || "");

  useEffect(() => {
    setFirstName(existingContact.firstName || "");
    setLastName(existingContact.lastName || "");
    setEmail(existingContact.email || "");
  }, [existingContact]);

  const updating = Object.keys(existingContact).length !== 0;

  const onSubmit = async (e) => {
    e.preventDefault();
    const data = { firstName, lastName, email };

    let response;
    if (updating) {
      response = await updateContact(existingContact.id, data);
    } else {
      response = await createContact(data);
    }

    if (response.message) {
      alert(response.message);
    }
    updateCallback();
  };

  return (
    <form onSubmit={onSubmit}>
      <div>
        <label>First Name:</label>
        <input
          type="text"
          value={firstName}
          onChange={(e) => setFirstName(e.target.value)}
          required
        />
      </div>
      <div>
        <label>Last Name:</label>
        <input
          type="text"
          value={lastName}
          onChange={(e) => setLastName(e.target.value)}
          required
        />
      </div>
      <div>
        <label>Email:</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </div>
      <button type="submit">{updating ? "Update" : "Create"}</button>
    </form>
  );
};

export default ContactForm;